import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]


def render(release, variables, template=None):
    path = template or ROOT / "src/helm/values" / release / "values.yml.tftpl"
    expression = f"jsonencode(yamldecode(templatefile({json.dumps(str(path))}, {json.dumps(variables)})))"
    with tempfile.TemporaryDirectory() as directory:
        result = subprocess.run(
            ["terraform", "console"], input=expression, text=True, capture_output=True,
            cwd=directory, check=True,
        )
    return json.loads(json.loads(result.stdout))


def gateway_variables(enabled):
    return {
        "namespace": "ai-gateway", "imageRepository": "docker.io/litellmenterprise/litellm",
        "imageTag": "1.101.5-enterprise", "imagePullSecret": "litellm-enterprise-pull",
        "serviceAccountName": "ai-gateway", "ingressHostname": "test.invalid",
        "proxyHostname": "test.invalid", "databaseSecret": "aurora",
        "databaseUserNameKey": "username", "databasePasswordKey": "password",
        "databaseEndpointKey": "host", "databaseReaderEndpointKey": "",
        "databaseName": "litellm", "databaseUsername": "litellm",
        "microsoft_foundry_tenant_id": "test-tenant", "microsoft_foundry_client_id": "test-client",
        "googleWorkloadIdentityAudience": "test-audience",
        "googleApplicationCredentialsConfigMap": "google-application-credentials",
        "masterkeySecretName": "litellm-master-key", "masterkeySecretKey": "master-key",
        "environmentSecrets": ["litellm-license", "litellm-entra-id", "elasticache"],
        "auditLogsBucket": "test-audit", "auditLogsRegion": "eu-west-2",
        "proxyAdminEmail": "admin@example.invalid", "minReplicas": 1, "maxReplicas": 3,
        "targetCPUUtilizationPercentage": 60, "ai_background_health_check_interval": 300,
        "openaiEnabled": enabled, "openaiApiBase": "http://litellm-openai.ai-gateway.svc.cluster.local:4000/v1",
        "openaiPolicyChecksum": "test-checksum",
    }


def backend_variables():
    return {
        "imageRepository": "docker.io/litellmenterprise/litellm",
        "imageTag": "1.101.5-enterprise", "imagePullSecret": "litellm-enterprise-pull",
        "serviceAccountName": "ai-gateway-openai", "masterkeySecret": "openai-proxy",
        "policyConfigMap": "openai-policy", "policyChecksum": "test-checksum",
        "logsBucket": "test-openai-logs", "logsRegion": "eu-west-2",
        "logsKeyArn": "arn:aws:kms:eu-west-2:123456789012:key/test",
        "models": [{"model_name": "gpt-5.4", "litellm_params": {"model": "openai/gpt-5.4"}}],
    }


class OpenAIConfigurationTests(unittest.TestCase):
    def test_model_is_development_only_and_restricted_to_data_platform(self):
        configuration = yaml.safe_load((ROOT / "configuration/configuration.yml").read_text())
        model = configuration["models"]["openai"]["gpt-5.4"]
        self.assertEqual(model["environments_available"], ["development"])
        self.assertFalse(model["generally_available"])
        assigned = [
            name for name, team in configuration["teams"].items()
            if "openai-gpt-5.4" in team.get("unified_access_groups", [])
        ]
        self.assertEqual(assigned, ["justice-data-platform"])

    def test_existing_releases_only_enable_forwarding_not_content_logging(self):
        for release in ("litellm", "litellm-admin"):
            for enabled in (False, True):
                with self.subTest(release=release, enabled=enabled):
                    values = render(release, gateway_variables(enabled))
                    settings = values["proxy_config"]["litellm_settings"]
                    self.assertFalse(settings["cache"])
                    self.assertNotIn("s3_v2", settings["success_callback"])
                    self.assertEqual("openai_policy.gateway" in settings["callbacks"], enabled)
                    self.assertEqual("openai-proxy" in values["environmentSecrets"], enabled)
                    self.assertEqual("PYTHONPATH" in values["envVars"], enabled)

    def test_backend_content_logging_cache_and_workload_identity(self):
        values = render("litellm-openai", backend_variables())
        settings = values["proxy_config"]["litellm_settings"]
        self.assertEqual(values["service"]["type"], "ClusterIP")
        self.assertFalse(values["ingress"]["enabled"])
        self.assertFalse(values["db"]["useExisting"])
        self.assertFalse(values["db"]["deployStandalone"])
        self.assertFalse(values["migrationJob"]["enabled"])
        self.assertEqual(values["masterkeySecretName"], "openai-proxy")
        self.assertEqual(settings["success_callback"], ["s3_v2"])
        self.assertEqual(settings["failure_callback"], ["s3_v2"])
        self.assertFalse(settings["turn_off_message_logging"])
        self.assertTrue(settings["cache"])
        self.assertEqual(settings["cache_params"]["ttl"], 300)
        self.assertTrue(settings["cache_params"]["ssl"])
        token = next(v for v in values["volumes"] if v["name"] == "openai-workload-identity-token")
        self.assertEqual(token["projected"]["sources"][0]["serviceAccountToken"]["audience"],
                         "https://api.openai.com/v1")
        self.assertNotIn("OPENAI_API_KEY", values["envVars"])
        self.assertEqual(values["envVars"]["OPENAI_PROMPT_LOG_BUCKET"], backend_variables()["logsBucket"])
        self.assertEqual(values["envVars"]["OPENAI_PROMPT_LOG_REGION"], backend_variables()["logsRegion"])
        self.assertEqual(values["envVars"]["OPENAI_PROMPT_LOG_KMS_KEY_ARN"], backend_variables()["logsKeyArn"])
        self.assertEqual(values["envVars"]["AWS_EC2_METADATA_DISABLED"], "True")

    @unittest.skipUnless(os.environ.get("LITELLM_CHART_PATH"), "Set LITELLM_CHART_PATH to the pinned Helm chart")
    def test_pinned_helm_chart_renders_isolated_backend(self):
        values = render("litellm-openai", backend_variables())
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "values.json"
            path.write_text(json.dumps(values))
            result = subprocess.run(
                ["helm", "template", "litellm-openai", os.environ["LITELLM_CHART_PATH"],
                 "--namespace", "ai-gateway", "--values", str(path)],
                text=True, capture_output=True, check=True,
            )
        documents = [item for item in yaml.safe_load_all(result.stdout) if item]
        deployment = next(item for item in documents if item["kind"] == "Deployment")
        pod = deployment["spec"]["template"]
        self.assertEqual(pod["metadata"]["labels"]["app.kubernetes.io/instance"], "litellm-openai")
        self.assertEqual(pod["spec"]["serviceAccountName"], "ai-gateway-openai")
        self.assertFalse(any(item["kind"] in ("Ingress", "StatefulSet", "Job") for item in documents))
        container = pod["spec"]["containers"][0]
        env = {item["name"]: item.get("value") for item in container["env"]}
        self.assertEqual(env["OPENAI_PROMPT_LOG_BUCKET"], backend_variables()["logsBucket"])
        self.assertEqual(env["OPENAI_PROMPT_LOG_KMS_KEY_ARN"], backend_variables()["logsKeyArn"])
        self.assertFalse(any(item["name"] == "DATABASE_URL" for item in container["env"]))
        proxy = next(item for item in container["env"] if item["name"] == "PROXY_MASTER_KEY")
        self.assertEqual(proxy["valueFrom"]["secretKeyRef"]["name"], "openai-proxy")
        config = next(item for item in documents if item["kind"] == "ConfigMap")
        proxy_config = yaml.safe_load(next(iter(config["data"].values())))
        self.assertEqual(proxy_config["model_list"][0]["litellm_params"]["model"], "openai/gpt-5.4")


if __name__ == "__main__":
    unittest.main()
