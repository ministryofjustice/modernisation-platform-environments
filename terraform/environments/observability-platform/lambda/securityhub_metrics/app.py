import json
import logging
import os
from typing import Any, Dict, Iterable, List

import boto3
from botocore.config import Config
from botocore.exceptions import ClientError

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

NAMESPACE = os.environ.get("METRIC_NAMESPACE", "ObservabilityPlatform/SecurityHub")
METRIC_NAME = os.environ.get("METRIC_NAME", "SecurityHubFindings")
MAX_METRICS_PER_CALL = 20

try:
    ACCOUNT_NAME_MAP = json.loads(os.environ.get("ACCOUNT_NAMES_JSON") or "{}")
except json.JSONDecodeError:
    LOGGER.warning("securityhub-invalid-account-map")
    ACCOUNT_NAME_MAP = {}

BOTO_CONFIG = Config(retries={"mode": "standard", "max_attempts": 5})
CLOUDWATCH = boto3.client("cloudwatch", config=BOTO_CONFIG)


def handler(event: Dict[str, Any], _context: Any) -> Dict[str, int]:
    findings = _extract_findings(event)
    if not findings:
        LOGGER.info("securityhub-no-findings", extra={"event_id": event.get("id")})
        return {"findings_processed": 0}

    metric_data = _build_metric_data(findings, event)
    _publish_metrics(metric_data)

    return {"findings_processed": len(findings)}


def _extract_findings(event: Dict[str, Any]) -> List[Dict[str, Any]]:
    detail = event.get("detail") or {}
    findings = detail.get("findings") or []
    if not isinstance(findings, list):
        LOGGER.warning("securityhub-invalid-findings-payload")
        return []
    return findings


def _build_metric_data(findings: Iterable[Dict[str, Any]], event: Dict[str, Any]) -> List[Dict[str, Any]]:
    region = event.get("region", "unknown")
    default_account = event.get("account", "unknown")

    metric_data: List[Dict[str, Any]] = []
    for finding in findings:
        severity = (finding.get("Severity") or {}).get("Label", "UNKNOWN")
        finding_account = finding.get("AwsAccountId", default_account)
        account_name = ACCOUNT_NAME_MAP.get(str(finding_account))

        dimensions = [
            {"Name": "SeverityLabel", "Value": str(severity)},
            {"Name": "AwsAccountId", "Value": str(finding_account)},
            {"Name": "Region", "Value": str(region)},
        ]
        if account_name:
            dimensions.append({"Name": "AccountName", "Value": str(account_name)})

        metric_data.append(
            {
                "MetricName": METRIC_NAME,
                "Dimensions": dimensions,
                "Value": 1,
                "Unit": "Count",
            }
        )

    metric_data.append(
        {
            "MetricName": METRIC_NAME,
            "Dimensions": [
                {"Name": "MetricType", "Value": "EventsProcessed"},
                {"Name": "Region", "Value": str(region)},
            ],
            "Value": 1,
            "Unit": "Count",
        }
    )

    return metric_data


def _publish_metrics(metric_data: List[Dict[str, Any]]) -> None:
    for chunk in _chunk(metric_data, MAX_METRICS_PER_CALL):
        try:
            CLOUDWATCH.put_metric_data(Namespace=NAMESPACE, MetricData=chunk)
        except ClientError as exc:
            LOGGER.error(
                "securityhub-metric-publish-failed",
                extra={
                    "error": exc.response.get("Error", {}),
                    "chunk_size": len(chunk),
                },
            )
            raise


def _chunk(items: List[Dict[str, Any]], size: int) -> Iterable[List[Dict[str, Any]]]:
    for start in range(0, len(items), size):
        yield items[start:start + size]
