import json
import logging
import os
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Protocol, TypedDict

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)


class LambdaContext(Protocol):
    """Protocol for AWS Lambda context object."""

    invoked_function_arn: str


class ACMEvent(TypedDict):
    detail_type: str
    resources: List[str]
    region: str
    account: str
    time: str
    id: str


@dataclass
class Config:
    """Configuration settings for the Lambda function."""

    expiry_days: int
    sns_topic_arn: Optional[str]
    security_hub_region: Optional[str]

    @classmethod
    def from_env(cls) -> "Config":
        """Create configuration from environment variables."""
        return cls(
            expiry_days=int(os.getenv("EXPIRY_DAYS", "45")),
            sns_topic_arn=os.getenv("SNS_TOPIC_ARN"),
            security_hub_region=os.getenv("SECURITY_HUB_REGION"),
        )


class CertificateMonitor:
    """Handles certificate monitoring and notification logic."""

    def __init__(self, config: Config):
        self.config = config
        self.expiry_window = datetime.now(timezone.utc) + timedelta(
            days=config.expiry_days
        )

    def get_security_hub_region(self, event_region: str) -> str:
        """Determine the Security Hub region to use."""
        return self.config.security_hub_region or event_region

    @staticmethod
    def get_certificate_id(cert_arn: str) -> str:
        """Extract certificate ID from ARN."""
        return cert_arn[-36:]

    def handle_single_certificate(
        self, event: ACMEvent, context_arn: str
    ) -> Dict[str, Any]:
        """Handle processing for a single certificate."""
        acm_client = boto3.client("acm")

        try:
            cert_response = acm_client.describe_certificate(
                CertificateArn=event["resources"][0]
            )
            cert_details = cert_response["Certificate"]

            days_to_expire = (
                cert_details["NotAfter"] - datetime.now(timezone.utc)
            ).days
            cert_id = self.get_certificate_id(cert_details["CertificateArn"])
            cert_domain = cert_details["DomainName"]
            region = cert_details["CertificateArn"].split(":")[3]

            message = (
                f"The following certificate will expire in {days_to_expire} days: {cert_domain}\n"
                f"{cert_details['CertificateArn']}\n\n"
                f"Click here to view it:\n"
                f"https://{region}.console.aws.amazon.com/acm/home?region={region}#/certificates/{cert_id}"
            )

            if cert_details["NotAfter"] < self.expiry_window:
                finding_result = self._process_expiring_certificate(
                    event, cert_details, context_arn
                )

                if self.config.sns_topic_arn:
                    self._send_sns_notification(message)

            return {"statusCode": 200, "body": message}

            return {"statusCode": 200, "body": result}

        except ClientError as e:
            logger.error(f"Error processing certificate: {e}")
            raise

    def _process_expiring_certificate(
        self, event: ACMEvent, cert_details: Dict[str, Any], context_arn: str
    ) -> str:
        """Process an expiring certificate and create Security Hub finding."""
        sh_region = self.get_security_hub_region(event["region"])
        sh_client = boto3.client("securityhub", region_name=sh_region)

        hub_arn = f"arn:aws:securityhub:{sh_region}:{event['account']}:hub/default"

        try:
            self._verify_security_hub(sh_client, hub_arn)
            finding = self._create_security_hub_finding(
                event, cert_details, context_arn
            )
            response = self._import_finding(sh_client, finding)
            return json.dumps(response)

        except ClientError as e:
            logger.error(f"Security Hub error: {e}")
            return "Security Hub disabled"

    def _verify_security_hub(self, sh_client: Any, hub_arn: str) -> None:
        """Verify Security Hub is enabled and accessible."""
        try:
            sh_client.describe_hub(HubArn=hub_arn)
        except ClientError as e:
            logger.warning(f"Security Hub not accessible: {e}")
            raise

    def _create_security_hub_finding(
        self, event: ACMEvent, cert_details: Dict[str, Any], context_arn: str
    ) -> Dict[str, Any]:
        """Create a Security Hub finding for an expiring certificate."""
        cert_id = self.get_certificate_id(cert_details["CertificateArn"])
        product_arn = f"arn:aws:securityhub:{event['region']}:{event['account']}:product/{event['account']}/default"

        return {
            "SchemaVersion": "2018-10-08",
            "Id": cert_id,
            "ProductArn": product_arn,
            "GeneratorId": context_arn,
            "AwsAccountId": event["account"],
            "Types": ["Software and Configuration Checks/AWS Config Analysis"],
            "CreatedAt": event["time"],
            "UpdatedAt": event["time"],
            "Severity": {"Original": "89.0", "Label": "HIGH"},
            "Title": "Certificate expiration",
            "Description": "Certificate approaching expiration date",
            "Remediation": {
                "Recommendation": {
                    "Text": f'A new certificate for {cert_details["DomainName"]} should be imported '
                    'to replace the existing imported certificate before expiration',
                    "Url": f"https://console.aws.amazon.com/acm/home?region={event['region']}#/?id={cert_id}",
                }
            },
            "Resources": [
                {
                    "Id": event["id"],
                    "Type": "ACM Certificate",
                    "Partition": "aws",
                    "Region": event["region"],
                }
            ],
            "Compliance": {"Status": "WARNING"},
        }

    def _import_finding(
        self, sh_client: Any, finding: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Import a finding into Security Hub."""
        try:
            response = sh_client.batch_import_findings(Findings=[finding])
            if response["FailedCount"] > 0:
                logger.error(f"Failed to import {response['FailedCount']} findings")
            return response
        except ClientError as e:
            logger.error(f"Error importing finding: {e}")
            raise

    def _send_sns_notification(self, message: str) -> None:
        """Send SNS notification about expiring certificate."""
        if not self.config.sns_topic_arn:
            return

        sns_client = boto3.client("sns")
        try:
            sns_client.publish(
                TopicArn=self.config.sns_topic_arn,
                Message=message,
                Subject="Certificate Expiration Notification",
            )
        except ClientError as e:
            logger.error(f"Error sending SNS notification: {e}")
            raise


def lambda_handler(event: ACMEvent, context: LambdaContext) -> Dict[str, Any]:
    """Main Lambda handler function."""
    try:
        if event.get("detail-type") != "ACM Certificate Approaching Expiration":
            return {"statusCode": 400, "body": "Invalid event type"}

        config = Config.from_env()
        monitor = CertificateMonitor(config)
        return monitor.handle_single_certificate(event, context.invoked_function_arn)

    except Exception as e:
        logger.error(f"Unhandled error: {e}", exc_info=True)
        return {"statusCode": 500, "body": f"Internal error: {str(e)}"}


if __name__ == "__main__":
    # For local testing
    from types import SimpleNamespace

    test_event = {
        "version": "0",
        "id": "9c95e8e4-96a4-ef3f-b739-b6aa5b193afb",
        "detail-type": "ACM Certificate Approaching Expiration",
        "source": "aws.acm",
        "account": "767123802783",
        "time": "2025-01-18T23:59:59Z",
        "region": "us-east-1",
        "resources": [
            "arn:aws:acm:eu-west-2:767123802783:certificate/82ddfdfe-2ca5-4782-bb01-21d6bc396d89"
        ],
        "detail": {"DaysToExpiry": 32, "CommonName": "*.dev.legalservices.gov.uk"},
    }
    test_context = SimpleNamespace(invoked_function_arn="arn:aws:lambda:...")
    print(lambda_handler(test_event, test_context))
