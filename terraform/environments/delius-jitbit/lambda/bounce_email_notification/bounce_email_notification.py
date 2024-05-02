import os
import boto3
import json
import time
from datetime import datetime
from botocore.exceptions import ClientError


def handler(event, context):
    todays_date = datetime.now().strftime("%Y-%m-%d")

    message = event["Records"][0]["Sns"]["Message"]
    message_dict = json.loads(message)

    mail = message_dict.get("mail")
    common_headers = mail.get("commonHeaders")
    headers = mail.get("headers")

    print(headers)

    jitbit_ticket_id_arr = list(
        filter(lambda id: id.get("name") == "X-Jitbit-TicketID", headers)
    )
    jitbit_ticket_id = jitbit_ticket_id_arr[0].get("value") if len(jitbit_ticket_id_arr) > 0 else "No Ticket ID Header"

    subject = common_headers.get("subject")
    reply_to = common_headers.get("replyTo")[0]
    source = mail.get("source")

    ses = boto3.client("sesv2")

    bounce = message_dict.get("bounce")

    bounced_recipients = bounce.get("bouncedRecipients")

    bounced_recipients_message = ""
    for bounced_recipient in bounced_recipients:
        bounced_recipients_message += f"""Action: {bounced_recipient.get("action")} for {bounced_recipient.get("emailAddress")}\n
                                        Status: {bounced_recipient.get("status")}\n
                                        Diagnostic Code: {bounced_recipient.get("diagnosticCode")}\n
                                        ---\n"""

    try:
        email = ses.send_email(
            FromEmailAddress=source,
            Destination={"ToAddresses": [reply_to]},
            ReplyToAddresses=[reply_to],
            Content={
                "Simple": {
                    "Subject": {"Data": f"BOUNCE <{jitbit_ticket_id}>: {subject}"},
                    "Body": {
                        "Text": {
                            "Data": f"""
                                    Ticket ID: {jitbit_ticket_id}\n
                                    Feedback ID: {bounce.get('feedbackId')}\n
                                    Timestamp: {bounce.get('timestamp')}\n
                                    Bounced Recipients:\n
                                        {bounced_recipients_message}\n
                                    """
                        }
                    },
                }
            },
        )

        print(f"Email sent: {email}")

    except ClientError as e:
        print(e)
