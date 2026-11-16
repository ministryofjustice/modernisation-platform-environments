import os
import sys
import tempfile
import unittest
from base64 import urlsafe_b64decode
from unittest import mock

from dulwich.objects import Blob, Commit, Tree
from dulwich.repo import Repo

os.environ.update(
    {
        "AWS_DEFAULT_REGION": "eu-west-2",
        "GITHUB_ORGANISATION": "example",
        "GITHUB_APP_SECRET_ARN": "arn:aws:secretsmanager:eu-west-2:123456789012:secret:test",
        "BACKUP_BUCKET": "approved-bucket",
    }
)
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# Avoid the AWS credential chain (and instance metadata lookups) at import time.
with mock.patch("boto3.client"):
    import main  # noqa: E402

PAGE_ONE = [
    {"repository_full_name": "example/public", "properties": [{"property_name": "backup", "value": "true"}]},
    {"repository_full_name": "example/disabled", "properties": [{"property_name": "backup", "value": "false"}]},
    {"repository_full_name": "example/missing", "properties": []},
]
PAGE_TWO = [
    {"repository_full_name": "example/private", "properties": [{"property_name": "backup", "value": True}]},
]


class AuthenticationTests(unittest.TestCase):
    def test_signs_app_jwt_and_requests_installation_token(self):
        public_key, private_key = main.rsa.newkeys(1024)
        secret = {
            "client_id": "Iv1.test",
            "installation_id": "42",
            "private_key": private_key.save_pkcs1().decode(),
        }
        with mock.patch.object(main, "secrets_manager") as secrets_manager, mock.patch.object(
            main, "github_request", return_value=({"token": "ghs_test"}, None)
        ) as request:
            secrets_manager.get_secret_value.return_value = {"SecretString": main.json.dumps(secret)}
            self.assertEqual(main.get_installation_token(), "ghs_test")

        path, jwt = request.call_args.args
        self.assertEqual(path, "/app/installations/42/access_tokens")
        header, payload, signature = jwt.split(".")
        padded = signature + "=" * (-len(signature) % 4)
        main.rsa.verify(f"{header}.{payload}".encode(), urlsafe_b64decode(padded), public_key)


class DiscoveryTests(unittest.TestCase):
    def test_paginates_and_filters_opted_in_repositories(self):
        responses = [(PAGE_ONE, "https://api.github.com/next"), (PAGE_TWO, None)]
        with mock.patch.object(main, "github_request", side_effect=responses) as request:
            self.assertEqual(main.discover_repositories("token"), ["example/private", "example/public"])
        self.assertEqual(request.call_args_list[0].args[0], "/orgs/example/properties/values?per_page=100")
        self.assertEqual(request.call_args_list[1].args[0], "https://api.github.com/next")

    def test_dispatches_one_async_invocation_per_repository(self):
        context = mock.Mock(invoked_function_arn="arn:aws:lambda:eu-west-2:123456789012:function:github-backup")
        with mock.patch.object(main, "get_installation_token", return_value="token"), mock.patch.object(
            main, "discover_repositories", return_value=["example/a", "example/b"]
        ), mock.patch.object(main, "lambda_client") as lambda_client:
            main.handler({}, context)
        self.assertEqual(lambda_client.invoke.call_count, 2)
        self.assertEqual(lambda_client.invoke.call_args.kwargs["InvocationType"], "Event")


class BackupTests(unittest.TestCase):
    def test_rejects_repositories_outside_the_organisation(self):
        for repository in ["other/repo", "example/../repo", "example/..", "example/"]:
            with self.assertRaises(ValueError):
                main.validate_repository(repository)

    def test_skips_repository_that_has_opted_out(self):
        properties = ([{"property_name": "backup", "value": "false"}], None)
        with mock.patch.object(main, "get_installation_token", return_value="token"), mock.patch.object(
            main, "github_request", return_value=properties
        ), mock.patch.object(main, "mirror_repository") as mirror, mock.patch.object(main, "s3") as s3:
            result = main.handler({"repository": "example/repo"}, None)
        self.assertTrue(result["skipped"])
        mirror.assert_not_called()
        s3.upload_file.assert_not_called()

    def test_uploads_date_partitioned_archive(self):
        properties = ([{"property_name": "backup", "value": "true"}], None)
        work_dir = os.path.join(tempfile.mkdtemp(), "work")
        os.makedirs(work_dir)
        stale_file = os.path.join(work_dir, "left-by-timed-out-run.tar.gz")
        open(stale_file, "w").close()

        def fake_mirror(_repository, _token, mirror_dir):
            self.assertFalse(os.path.exists(stale_file))
            os.makedirs(mirror_dir)
            with open(os.path.join(mirror_dir, "HEAD"), "w") as head:
                head.write("ref: refs/heads/main\n")

        with mock.patch.object(main, "WORK_DIR", work_dir), mock.patch.object(
            main, "get_installation_token", return_value="token"
        ), mock.patch.object(main, "github_request", return_value=properties), mock.patch.object(
            main, "mirror_repository", side_effect=fake_mirror
        ), mock.patch.object(
            main, "s3"
        ) as s3:
            result = main.handler({"repository": "example/repo"}, None)

        _path, bucket, key = s3.upload_file.call_args.args
        self.assertEqual(bucket, "approved-bucket")
        self.assertRegex(key, r"^example/repo/\d{8}/repo-\d{8}T\d{6}Z-[0-9a-f]{8}\.tar\.gz$")
        self.assertEqual(result["key"], key)
        self.assertFalse(os.path.exists(work_dir))


class ConnectivityTests(unittest.TestCase):
    def setUp(self):
        self.repo = Repo.init_bare(tempfile.mkdtemp())
        self.addCleanup(self.repo.close)
        blob = Blob.from_string(b"content")
        self.tree = Tree()
        self.tree.add(b"file.txt", 0o100644, blob.id)
        self.repo.object_store.add_objects([(blob, None), (self.tree, None)])

    def commit(self, parents=()):
        commit = Commit()
        commit.tree = self.tree.id
        commit.parents = list(parents)
        commit.author = commit.committer = b"Test <test@example.com>"
        commit.author_time = commit.commit_time = 0
        commit.author_timezone = commit.commit_timezone = 0
        commit.message = b"test"
        self.repo.object_store.add_object(commit)
        return commit

    def test_accepts_complete_history(self):
        self.repo.refs[b"refs/heads/main"] = self.commit(parents=[self.commit().id]).id
        main.check_connectivity(self.repo)

    def test_rejects_missing_parent(self):
        self.repo.refs[b"refs/heads/main"] = self.commit(parents=[b"0" * 40]).id
        with self.assertRaisesRegex(RuntimeError, "Missing object"):
            main.check_connectivity(self.repo)


if __name__ == "__main__":
    unittest.main()
