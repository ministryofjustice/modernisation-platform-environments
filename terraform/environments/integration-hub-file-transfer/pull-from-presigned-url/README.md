# Pull from presigned URL

After retaining a clean file, the notifier publishes a custom notification to a
recipient-specific encrypted SNS topic. The Modernisation Platform Chatbot module
connects that topic to Slack. No incoming webhook or new Slack app is needed.

Development targets `#integration-hub-team` (`C0ARA0C101L`) in the Justice Digital
workspace (`T02DYEB3A`). The AWS account must first be connected to that workspace
in Amazon Q Developer in chat applications (formerly AWS Chatbot). This is a
one-time account setup; the Terraform module cannot perform the Slack OAuth step.
AWS commands are disabled for this notification integration.

Apply the root dispatch configuration before this component. After applying, upload
a fresh harmless file through the API. Check the retained S3 copy, SNS publication
and the actual Slack message. A `published` worker outcome confirms SNS accepted
it; it does not prove Slack delivery. The message includes the portal link and a
URL-encoded object location, not a presigned S3 URL. The development trial grants the existing `integration-hub` Identity Center group
read-only access to `products-poc-slack-test/` in the pickup bucket. It does not
grant upload/delete access or access to other recipient directories.

The former webhook secret is no longer read and Terraform schedules it for deletion
with its 30-day recovery window. It does not need to be populated.

The supported pattern and operations guide are maintained in the
[Integration Hub documentation](https://github.com/ministryofjustice/integration-hub/pull/233).

Run the notifier tests from the repository root:

```sh
PYTHONPATH=terraform/environments/integration-hub-file-transfer/pull-from-presigned-url/lambda/notifier \
  python3 -m unittest discover -s terraform/environments/integration-hub-file-transfer/pull-from-presigned-url/lambda/notifier/tests -v
```
