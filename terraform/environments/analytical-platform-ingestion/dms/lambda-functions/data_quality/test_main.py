import os
import unittest
from datetime import datetime, timezone
from unittest import mock

os.environ.setdefault("AWS_DEFAULT_REGION", "eu-west-2")
os.environ["PIPELINES"] = '{"tariff-production": {"task_arn": "arn:task", "deadline": "01:30", "exclude_tables": []}}'

import main  # noqa: E402

TODAY = datetime(2026, 11, 25, tzinfo=timezone.utc)


def task(status="stopped", stop_reason="Stop Reason FULL_LOAD_ONLY_FINISHED", started=datetime(2026, 11, 25, 0, 30, tzinfo=timezone.utc)):
    return {"Status": status, "StopReason": stop_reason, "ReplicationTaskStats": {"StartDate": started}}


class TestThresholds(unittest.TestCase):
    def test_row_drop_needs_enough_history(self):
        self.assertIsNone(main.row_drop_baseline(0, [10000, 10000]))

    def test_row_drop_alerts_on_large_drop(self):
        self.assertEqual(main.row_drop_baseline(5000, [10000, 10000, 10000]), 10000)

    def test_row_drop_ignores_small_absolute_drop(self):
        self.assertIsNone(main.row_drop_baseline(500, [1000, 1000, 1000]))

    def test_row_drop_ignores_growth(self):
        self.assertIsNone(main.row_drop_baseline(20000, [10000, 10000, 10000]))

    def test_duration_overrun_alerts(self):
        self.assertEqual(main.duration_overrun_baseline(200, [120, 125, 118]), 120)

    def test_duration_overrun_ignores_small_absolute_overrun(self):
        self.assertIsNone(main.duration_overrun_baseline(5, [2, 2, 2]))


class TestRunStatus(unittest.TestCase):
    def test_finished(self):
        self.assertEqual(main.run_status(task(), TODAY)[0], "finished")

    def test_running(self):
        self.assertEqual(main.run_status(task(status="running", stop_reason=""), TODAY)[0], "running")

    def test_missing(self):
        self.assertEqual(main.run_status(task(started=datetime(2026, 11, 24, 0, 30, tzinfo=timezone.utc)), TODAY)[0], "missing")

    def test_failed(self):
        self.assertEqual(main.run_status(task(stop_reason="Stop Reason FATAL_ERROR"), TODAY)[0], "failed")


class TestCheckRun(unittest.TestCase):
    @mock.patch.object(main, "publish")
    @mock.patch.object(main, "put_metrics")
    @mock.patch.object(main, "metric_values")
    @mock.patch.object(main, "table_statistics")
    @mock.patch.object(main, "describe_task")
    def test_alerts_on_drop_and_error(self, describe_task, table_statistics, metric_values, put_metrics, publish):
        describe_task.return_value = {"ReplicationTaskStats": {"ElapsedTimeMillis": 120000}}
        table_statistics.return_value = [
            {"SchemaName": "dbo", "TableName": "A", "FullLoadRows": 100, "TableState": "Table completed"},
            {"SchemaName": "dbo", "TableName": "B", "FullLoadRows": 5000, "TableState": "Table error"},
        ]
        metric_values.return_value = {
            "dbo.A": [5000, 5000, 5000],
            "dbo.B": [5000, 5000, 5000],
            main.DURATION_KEY: [2, 2, 2],
        }

        main.check_run("tariff-production")

        message = publish.call_args[0][0]
        self.assertIn("📉 dbo.A: 100 rows (usual 5,000, -98%)", message)
        self.assertIn("🚫 dbo.B: Table error", message)
        issues_metric = [m for m in put_metrics.call_args[0][0] if m["MetricName"] == "IssuesFound"][0]
        self.assertEqual(issues_metric["Value"], 2)

    @mock.patch.object(main, "publish")
    @mock.patch.object(main, "put_metrics")
    @mock.patch.object(main, "metric_values")
    @mock.patch.object(main, "table_statistics")
    @mock.patch.object(main, "describe_task")
    def test_quiet_when_normal(self, describe_task, table_statistics, metric_values, put_metrics, publish):
        describe_task.return_value = {"ReplicationTaskStats": {"ElapsedTimeMillis": 120000}}
        table_statistics.return_value = [
            {"SchemaName": "dbo", "TableName": "A", "FullLoadRows": 5000, "TableState": "Table completed"},
        ]
        metric_values.return_value = {"dbo.A": [5000, 4900, 5100], main.DURATION_KEY: [2, 2, 2]}

        main.check_run("tariff-production")

        publish.assert_not_called()
        put_metrics.assert_called_once()


class TestSettledTableStatistics(unittest.TestCase):
    @mock.patch.object(main.time, "sleep")
    @mock.patch.object(main, "table_statistics")
    def test_waits_until_tables_complete(self, table_statistics, sleep):
        loading = [{"SchemaName": "dbo", "TableName": "VARIABLE", "TableState": "Full load"}]
        done = [{"SchemaName": "dbo", "TableName": "VARIABLE", "TableState": "Table completed"}]
        table_statistics.side_effect = [loading, loading, done]

        self.assertEqual(main.settled_table_statistics("arn:task"), done)
        self.assertEqual(sleep.call_count, 2)

    @mock.patch.object(main.time, "sleep")
    @mock.patch.object(main, "table_statistics")
    def test_gives_up_after_max_attempts(self, table_statistics, sleep):
        loading = [{"SchemaName": "dbo", "TableName": "VARIABLE", "TableState": "Full load"}]
        table_statistics.return_value = loading

        self.assertEqual(main.settled_table_statistics("arn:task"), loading)
        self.assertEqual(table_statistics.call_count, main.SETTLE_ATTEMPTS)


class TestDigest(unittest.TestCase):
    @mock.patch.object(main, "publish")
    @mock.patch.object(main, "metric_values")
    @mock.patch.object(main, "table_statistics")
    @mock.patch.object(main, "describe_task")
    @mock.patch.object(main, "today_start", return_value=TODAY)
    def test_lists_tables_under_task(self, _, describe_task, table_statistics, metric_values, publish):
        describe_task.return_value = {
            **task(),
            "ReplicationTaskIdentifier": "cica-ap-tariff-production-full-load",
            "ReplicationTaskStats": {
                "StartDate": datetime(2026, 11, 25, 0, 30, tzinfo=timezone.utc),
                "FullLoadStartDate": datetime(2026, 11, 25, 0, 30, tzinfo=timezone.utc),
                "FullLoadFinishDate": datetime(2026, 11, 25, 1, 0, tzinfo=timezone.utc),
            },
        }
        table_statistics.return_value = [
            {
                "SchemaName": "dbo", "TableName": "A", "FullLoadRows": 900, "TableState": "Table completed",
                "FullLoadEndTime": datetime(2026, 11, 25, 0, 45, tzinfo=timezone.utc),
            },
            {"SchemaName": "dbo", "TableName": "B", "FullLoadRows": 0, "TableState": "Table error"},
        ]
        metric_values.return_value = {
            f"tariff-production|{main.DURATION_KEY}": [20, 20, 20],
            f"tariff-production|{main.TOTAL_ROWS_KEY}": [1000, 1000, 1000],
            "tariff-production|dbo.A": [1000, 1000, 1000],
            "tariff-production|dbo.B": [],
        }

        main.send_digest()

        self.assertEqual(
            publish.call_args[0][0],
            [
                "📋 DMS daily summary 2026-11-25",
                "",
                "⚠️ tariff-production (cica-ap-tariff-production-full-load)",
                "Finished 01:00 UTC in 30m (usual 20m, +50%), 900 rows (usual 1,000, -10%), 2 tables",
                "    • dbo.A: 900 rows (usual 1,000, -10%), done 00:45 UTC",
                "    • dbo.B: 0 rows, 🚫 Table error",
            ],
        )


if __name__ == "__main__":
    unittest.main()
