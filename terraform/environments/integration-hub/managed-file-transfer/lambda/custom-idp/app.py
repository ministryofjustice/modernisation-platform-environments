import os

from aws_lambda_powertools import Logger


logger = Logger(service=os.getenv("POWERTOOLS_SERVICE_NAME", "integration-hub-managed-file-transfer-custom-idp"))


@logger.inject_lambda_context(clear_state=True, log_event=False)
def lambda_handler(event, _context):
    logger.warning(
        "Custom identity provider foundations are provisioned but not yet wired into an AWS Transfer server",
        extra={
            "server_id": event.get("serverId"),
            "username": event.get("username"),
        },
    )

    return {}