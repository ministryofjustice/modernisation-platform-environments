import csv
import re
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SQL_PATH = ROOT / "dormant_user_activity_rules.sql"
FIXTURES = ROOT / "tests" / "fixtures"
CUTOFF = datetime(2026, 10, 13, tzinfo=timezone.utc)
WINDOW_DAYS = 30
BUSINESS_VALUES = {"ministry-of-justice-uk", "Ministry of Justice (UK)"}


def read_values_cte(name):
    sql = SQL_PATH.read_text()
    pattern = re.compile(
        rf"{name}\s*\([^)]*\)\s+AS\s*\(\s*VALUES(?P<rows>.*?)\n\)",
        re.DOTALL,
    )
    match = pattern.search(sql)
    if not match:
        raise AssertionError(f"Could not find VALUES CTE {name}")

    parsed = []
    for line in match.group("rows").splitlines():
        line = line.strip().rstrip(",")
        if not line.startswith("(") or not line.endswith(")"):
            continue
        parsed.append(next(csv.reader([line[1:-1]], delimiter=",", quotechar="'", skipinitialspace=True)))
    return parsed


def read_csv(path):
    with path.open(newline="") as stream:
        return list(csv.DictReader(stream))


def as_bool(value):
    return value.strip().lower() == "true"


def qualifies(event, rule, subject_type, include_sso=True):
    if event["business"] not in BUSINESS_VALUES:
        return False
    if rule["observable"] != "TRUE":
        return False
    if rule["rule_id"] == "R01_saml_sso" and not include_sso:
        return False

    if subject_type == "actor":
        if as_bool(event["actor_is_bot"]) or as_bool(event["actor_is_agent"]):
            return False
        access_type = event["programmatic_access_type"].lower()
        if (
            "personal access token" in access_type
            or access_type.startswith("public key")
            or access_type.startswith("github app")
        ):
            return False

    if event["action"] == "git.push":
        if event["transport_protocol_name"].lower() not in {"http", "https"}:
            return False
        if as_bool(event["repository_public"]):
            return False
        if event["visibility"].lower() != "internal":
            return False

    event_time = datetime.fromtimestamp(int(event["event_timestamp"]) / 1000, timezone.utc)
    if event_time < CUTOFF - timedelta(days=WINDOW_DAYS) or event_time >= CUTOFF:
        return False

    subject_id = event["actor_id"] if subject_type == "actor" else event["user_id"]
    return bool(subject_id)


class DormantUserRuleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        catalog_rows = read_values_cte("rule_catalog")
        cls.rules = {
            row[0]: {
                "rule_id": row[0],
                "rule_name": row[1],
                "observable": row[2].upper(),
                "limitation": row[3],
            }
            for row in catalog_rows
        }
        cls.actions = read_values_cte("rule_actions")
        cls.action_map = {}
        for rule_id, action, subject_type in cls.actions:
            cls.action_map.setdefault(action, []).append((rule_id, subject_type))
        cls.events = read_csv(FIXTURES / "audit_events.csv")
        cls.population = read_csv(FIXTURES / "population.csv")
        cls.allowlist = read_csv(FIXTURES / "user_allowlist.csv")
        cls.repo_visibility = {
            row["repo"].lower(): row["visibility"].lower()
            for row in read_csv(FIXTURES / "repository_visibility.csv")
        }
        cls.sql = SQL_PATH.read_text()

    def active_user_ids(self, include_sso=True):
        active = set()
        for event in self.events:
            for rule_id, subject_type in self.action_map.get(event["action"], []):
                prepared_event = dict(event)
                prepared_event["visibility"] = event["visibility"] or self.repo_visibility.get(
                    event["repo"].lower(), ""
                )
                if qualifies(prepared_event, self.rules[rule_id], subject_type, include_sso):
                    active.add(int(event["user_id"] if subject_type == "user" else event["actor_id"]))
        return active

    def test_catalogue_has_twenty_rules_and_fourteen_observable_mappings(self):
        self.assertEqual(len(self.rules), 20)
        self.assertEqual(sum(rule["observable"] == "TRUE" for rule in self.rules.values()), 14)

    def test_unobservable_rules_are_explicit(self):
        self.assertEqual(
            {
                rule_id
                for rule_id, rule in self.rules.items()
                if rule["observable"] == "FALSE"
            },
            {
                "R09_labels",
                "R10_assign",
                "R14_pr_synchronize",
                "R16_release_publish",
                "R17_wiki_push",
                "R18_star_repo",
            },
        )

    def test_partial_mappings_and_limitations_are_preserved(self):
        self.assertIn("success is not recorded", self.rules["R01_saml_sso"]["limitation"])
        self.assertIn("proxy", self.rules["R07_pr_comment"]["limitation"])
        self.assertIn("plain conversation comments are not logged", self.rules["R07_pr_comment"]["limitation"])
        self.assertIn("issue close and reopen are not logged", self.rules["R08_close_reopen"]["limitation"])
        self.assertIn("proxy", self.rules["R13_dismiss_review"]["limitation"])
        self.assertIn("update only", self.rules["R15_commit_comment"]["limitation"])

    def test_action_mapping_matches_documented_rules_and_subjects(self):
        expected = {
            ("R01_saml_sso", "org.sso_response", "actor"),
            ("R02_repo_create", "repo.create", "actor"),
            ("R03_push_internal_https", "git.push", "actor"),
            ("R04_added_to_repo", "repo.add_member", "user"),
            ("R05_repo_visibility", "repo.access", "actor"),
            ("R06_pr_create", "pull_request.create", "actor"),
            ("R07_pr_comment", "pull_request_review.submit", "actor"),
            ("R08_close_reopen", "pull_request.close", "actor"),
            ("R08_close_reopen", "pull_request.reopen", "actor"),
            ("R11_review_request", "pull_request.create_review_request", "actor"),
            ("R11_review_request", "pull_request.remove_review_request", "actor"),
            ("R12_review_comment", "pull_request_review_comment.create", "actor"),
            ("R12_review_comment", "pull_request_review_comment.update", "actor"),
            ("R13_dismiss_review", "pull_request_review.dismiss", "actor"),
            ("R15_commit_comment", "commit_comment.update", "actor"),
            ("R19_repo_delete", "repo.destroy", "actor"),
            ("R20_join_org", "org.add_member", "user"),
        }
        self.assertEqual({tuple(row) for row in self.actions}, expected)

    def test_synthetic_activity_uses_user_id_and_expected_candidate_population(self):
        active = self.active_user_ids()
        population_ids = {int(row["user_id"]) for row in self.population}
        allowlisted_ids = {int(row["user_id"]) for row in self.allowlist}
        self.assertEqual(active, {101, 102, 103, 107, 110, 116})
        self.assertEqual(
            population_ids - active - allowlisted_ids,
            {104, 105, 106, 108, 111, 112, 113, 114, 117, 118, 119, 120, 901},
        )

    def test_allowlist_excludes_by_stable_user_id(self):
        allowlisted_ids = {int(row["user_id"]) for row in self.allowlist}
        self.assertEqual(allowlisted_ids, {109})
        self.assertIn(109, {int(row["user_id"]) for row in self.population})
        self.assertIn("AND al.user_id IS NULL", self.sql)

    def test_recipient_events_credit_added_user_not_actor(self):
        active = self.active_user_ids()
        self.assertIn(102, active)
        self.assertIn(110, active)
        self.assertNotIn(901, active)
        self.assertNotIn(111, active)

    def test_pushes_require_https_and_internal_non_public_repository(self):
        active = self.active_user_ids()
        self.assertIn(103, active)
        self.assertNotIn(104, active)
        self.assertNotIn(105, active)
        self.assertNotIn(106, active)

    def test_push_visibility_falls_back_to_dated_repository_snapshot(self):
        internal_push = next(event for event in self.events if event["event_id"] == "synthetic-03")
        self.assertEqual(internal_push["visibility"], "")
        self.assertEqual(self.repo_visibility[internal_push["repo"]], "internal")
        self.assertIn("LOWER(COALESCE(e.visibility, rv.visibility))", self.sql)
        self.assertIn("report_repository_visibility", self.sql)

    def test_unknown_repository_visibility_does_not_count_a_push(self):
        unknown_push = next(event for event in self.events if event["event_id"] == "synthetic-03")
        unknown_push = dict(unknown_push, repo="beta/not-in-snapshot")
        unknown_push["visibility"] = self.repo_visibility.get(unknown_push["repo"], "")
        self.assertFalse(qualifies(unknown_push, self.rules["R03_push_internal_https"], "actor"))

    def test_actor_bot_agent_and_token_events_do_not_qualify(self):
        active = self.active_user_ids()
        self.assertTrue({108, 109, 117, 118, 119, 120}.isdisjoint(active))

    def test_window_is_inclusive_at_start_and_exclusive_at_cutoff(self):
        boundary_start = {
            "business": "ministry-of-justice-uk",
            "action": "repo.create",
            "actor_id": "201",
            "user_id": "",
            "actor_is_bot": "false",
            "actor_is_agent": "false",
            "programmatic_access_type": "",
            "transport_protocol_name": "",
            "repository_public": "false",
            "visibility": "internal",
        }
        action_rule = self.rules["R02_repo_create"]
        boundary_start["event_timestamp"] = str(
            int((CUTOFF - timedelta(days=WINDOW_DAYS)).timestamp() * 1000)
        )
        self.assertTrue(qualifies(boundary_start, action_rule, "actor"))
        boundary_start["event_timestamp"] = str(int(CUTOFF.timestamp() * 1000))
        self.assertFalse(qualifies(boundary_start, action_rule, "actor"))

    def test_sso_can_be_removed_from_observable_denominator(self):
        active_with_sso = self.active_user_ids(include_sso=True)
        active_without_sso = self.active_user_ids(include_sso=False)
        self.assertEqual(active_with_sso - active_without_sso, {116})
        self.assertEqual(sum(r["observable"] == "TRUE" for r in self.rules.values()), 14)
        self.assertEqual(
            sum(
                r["observable"] == "TRUE" and rule_id != "R01_saml_sso"
                for rule_id, r in self.rules.items()
            ),
            13,
        )
        self.assertEqual(
            self.sql.count("r.rule_id <> 'R01_saml_sso' OR p.include_sso"),
            2,
        )

    def test_query_has_partition_timestamp_and_exclusion_filters(self):
        for fragment in (
            "e.datehour >= p.datehour_start",
            "e.datehour < p.datehour_end",
            "e.event_timestamp >= CAST(",
            "e.event_timestamp < CAST(",
            "NOT COALESCE(e.actor_is_bot, FALSE)",
            "NOT COALESCE(e.actor_is_agent, FALSE)",
            "personal access token",
            "public key%",
            "github app%",
            "LOWER(e.transport_protocol_name) IN ('http', 'https')",
            "e.effective_visibility = 'internal'",
            "NOT COALESCE(e.repository_public, FALSE)",
            "LOWER(COALESCE(e.visibility, rv.visibility))",
            "WHERE COALESCE(a.rules_satisfied, 0) = 0",
        ):
            self.assertIn(fragment, self.sql)

    def test_excluded_event_counters_remain_in_candidate_output(self):
        for column in (
            "excluded_token_ssh_app_events",
            "excluded_git_ops_events",
            "excluded_issue_events",
        ):
            self.assertIn(column, self.sql)
        self.assertIn("e.action LIKE 'issue.%'", self.sql)
        self.assertIn("e.action LIKE 'issues.%'", self.sql)
        self.assertIn("e.action LIKE 'issue_comment.%'", self.sql)


if __name__ == "__main__":
    unittest.main()
