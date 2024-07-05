import os
import boto3
import json
import time
from datetime import datetime
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key, Attr


def handler(event, context):
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(os.environ["DYNAMODB_TABLE"])

    # generate ttl 840 minutes from now (840 minutes is the typical retry period for mail servers)
    ttl = int(time.time()) + int(os.environ.get("TTL", "840")) * 60
    # this rate limit is per the ttl delta defined above
    rate_limit = os.environ["RATE_LIMIT"]

    message = event["Records"][0]["Sns"]["Message"]
    message_dict = json.loads(message)

    mail = message_dict.get("mail")
    common_headers = mail.get("commonHeaders")
    headers = mail.get("headers")

    from_address = os.environ.get("FROM_ADDRESS")

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

    feedback_id = bounce.get("feedbackId")

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    try:
        response = table.update_item(
          Key={"email_ticket_id": f"{source}|{jitbit_ticket_id}"},
          UpdateExpression="SET #count = if_not_exists(#count, :initial) + :increment, expiresAt = if_not_exists(expiresAt, :ttl)",
          ExpressionAttributeNames={"#count": "count"},
          ExpressionAttributeValues={
              ":increment": 1,
              ":initial": 0,
              ":ttl": ttl,
              ":current_timestamp": int(time.time()),
          },
          ConditionExpression="attribute_not_exists(expiresAt) OR expiresAt > :current_timestamp",
          ReturnValues="ALL_NEW",
      )
    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        print("DynamoDB conditional check result - record is expired")
        # if the record is expired then we need to reset the count and the ttl
        response = table.update_item(
            Key={"email_ticket_id": f"{source}|{jitbit_ticket_id}"},
            UpdateExpression="SET #count = :initial, expiresAt = :ttl",
            ExpressionAttributeNames={"#count": "count"},
            ExpressionAttributeValues={
                ":initial": 0,
                ":ttl": ttl
            },
            ReturnValues="ALL_NEW",
        )

    print(response)

    print(f"Rate limit: {rate_limit}")

    print(f"Rate limit count: {response.get('Attributes').get('count')}")

    rate_limit_warning_message = ""
    # if the count is not none and greater than the rate limit then exit
    if response.get("Attributes") is not None and response.get("Attributes").get("count") > int(rate_limit):
        print(f"Rate limit exceeded for {source} on ticket id {jitbit_ticket_id}")
        return None
    # if the count is not none and 1 less than the rate limit
    elif response.get("Attributes") is not None and int(response.get("Attributes").get("count")) == int(rate_limit) - 1:
        rate_limit_warning_message = f"""  <p>
                                    <strong>RATE LIMIT WARNING:</strong>
                                    <br>
                                    <p>
                                        The rate limit of {rate_limit} will be reached for the email address <strong>{source}</strong> and ticket ID <strong>{jitbit_ticket_id}</strong> on the next notification.
                                        Further notifications will not be sent until the rate limit has been reset.
                                    </p>
                                </p>
                            """
    elif response.get("Attributes") is not None and int(response.get("Attributes").get("count")) == int(rate_limit):
        rate_limit_warning_message = f"""  <p>
                                    <strong>RATE LIMIT WARNING:</strong>
                                    <br>
                                    <p>
                                        The rate limit of {rate_limit} has been reached for the email address <strong>{source}</strong> and ticket ID <strong>{jitbit_ticket_id}</strong>.
                                        Further notifications will not be sent until the rate limit has been reset.
                                    </p>
                                </p>
                            """

    bounced_recipients_message = ""
    for bounced_recipient in bounced_recipients:
        bounced_recipients_message += f"""  <p>
                                                Action: <strong>{bounced_recipient.get("action")}</strong>
                                                <br>
                                            </p>
                                            <p>
                                                Recipient: <strong>{bounced_recipient.get("emailAddress")}</strong>
                                                <br>
                                            </p>
                                            <p>
                                                Status: <strong>{bounced_recipient.get("status")}</strong>
                                                <br>
                                            </p>
                                            <p>
                                                Diagnostic Code: <strong>{bounced_recipient.get("diagnosticCode")}</strong>
                                            </p>
                                          """

    try:
        email = ses.send_email(
            FromEmailAddress=from_address,
            Destination={"ToAddresses": [reply_to]},
            ReplyToAddresses=[reply_to],
            Content={
                "Simple": {
                    "Subject": {"Data": f"BOUNCE <{jitbit_ticket_id}>: {subject} #tech#"},
                    "Body": {
                        "Html": {
                            "Data": f"""
                                    {rate_limit_warning_message}
                                    <table width="100%" style="background-color: rgb(250, 232, 205);">
                                    <tbody>
                                      <tr>
                                        <td style="background-color: rgb(255, 50, 50);"></td>
                                        <td>&nbsp;&nbsp;</td>
                                        <td width="100%">
                                          <br>
                                          <strong>WARNING:</strong>
                                          <br>
                                          <p> An email notification from this ticket has failed to deliver to one or more recipients. This may be the result of a 'Reply' or a 'Forward Ticket By Email'. See the diagnostic information below for more details. We have provided a simple guide <a href="https://helpdesk.jitbit.cr.probation.service.justice.gov.uk/KB/View/976525-">HERE</a> which explains the actions that you need to take.
                                            <br>
                                          </p>
                                        </td>
                                      </tr>
                                    </tbody>
                                  </table>
                                  <br>
                                  <hr>
                                  <br>
                                  <strong>DIAGNOSTIC INFORMATION:</strong>
                                  <br>
                                  <br>
                                  <table width="100%" style="background-color: rgb(240, 240, 240);">
                                    <tbody>
                                        <tr>
                                            <td style="background-color: rgb(150, 150, 150);"></td>
                                            <td>&nbsp;&nbsp;</td>
                                            <td width="100%">
                                              <br>
                                              <p>Ticket ID: <strong>{jitbit_ticket_id}</strong>
                                              </p>
                                              <p>Feedback ID: <strong>{feedback_id}</strong>
                                                <br>
                                              </p>
                                              <p>Timestamp: <strong>{timestamp}</strong>
                                                <br>
                                              </p>
                                        </tr>
                                        <tr>
                                        <td style="background-color: rgb(150, 150, 150);"></td>
                                            <td>&nbsp;&nbsp;</td>
                                            <td>
                                                <p><strong>Bounced Recipients:</strong></p>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td style="background-color: rgb(150, 150, 150);"></td>
                                            <td>&nbsp;&nbsp;</td>
                                            <td width="100%">
                                              {bounced_recipients_message}
                                            </td>
                                          </tr>
                                    </tbody>
                                  </table>
                                  <br>
                                  <br>
                                """
                        }
                    },
                }
            },
        )

        print(f"Email sent: {email}")

    except ClientError as e:
        print(e)
