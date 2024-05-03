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
        bounced_recipients_message += f"""  <p>
                                                Action: <strong>{bounced_recipient.get("action")}</strong>
                                                <br>
                                            </p>
                                            <p>
                                                Recipient: <strong>{bounced_recipient.get("emailAddress")}/strong>
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
            FromEmailAddress=source,
            Destination={"ToAddresses": [reply_to]},
            ReplyToAddresses=[reply_to],
            Content={
                "Simple": {
                    "Subject": {"Data": f"BOUNCE <{jitbit_ticket_id}>: {subject}"},
                    "Body": {
                        "Html": {
                            "Data": f"""
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
                                              <p>Feedback ID: <strong>010b018f3d5323b8-1afeb777-87b9-4433-8104-f2f265151de6-000000</strong>
                                                <br>
                                              </p>
                                              <p>Timestamp: <strong>2024-05-03T07:20:10.035Z</strong>
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
