locals {
  eventbridge_schema_directory = "${path.module}/schemas"
  eventbridge_schemas          = fileset("${path.module}/schemas", "*.json")

  eventbridge_retention_days = local.is-production ? 400 : 30

  filereceived_transformer = {
    input_paths = {
      account_id = "$.account"
      bucket     = "$.detail.bucket.name"
      event_id   = "$.id"
      object_key = "$.detail.object.key"
      region     = "$.region"
      size_bytes = "$.detail.object.size"
      timestamp  = "$.time"
      version_id = "$.detail.object.version-id"
    }

    input_template = <<-EOF
      {
        "version": "0",
        "id": <event_id>,
        "detail-type": "FileReceived.v1",
        "source": "uk.gov.justice.service.managed-file-transfer",
        "account": <account_id>,
        "time": <timestamp>,
        "region": <region>,
        "detail": {
          "metadata": {
            "correlationId": <event_id>,
            "idempotencyKey": "<bucket>:<object_key>:<version_id>"
          },
          "data": {
            "fileId": <event_id>,
            "object": {
              "bucket": <bucket>,
              "key": <object_key>,
              "versionId": <version_id>,
              "sizeBytes": <size_bytes>
            },
            "provenance": {
              "ingressMethod": "s3"
            }
          }
        }
      }
    EOF
  }
}
