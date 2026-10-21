# S3 -> OpenSearch log ingestion (#8419): Fluent Bit writes to S3 (cluster/
# fluent-bit-s3.tf, logs/); S3 Object Created events go via EventBridge -> SQS;
# an OSIS pipeline reads the queue and indexes into the domain. EventBridge (not
# a bucket notification) lets one bucket fan out to several consumers.
# Depends on `eventbridge = true` on the bucket, set in `cluster`.
# See ADR-017 (OpenSearch section).

locals {
  # Phase-2 gate (same as opensearch-objects.tf). Off until deliberately enabled,
  # because: the source bucket is owned by the `cluster` component and named per
  # ephemeral cluster (cp-DDMM-HHMM), so it does NOT exist as
  # <root-workspace>-fluentbit — the data source below can't resolve it from root
  # yet, and the cross-account forwarding (ADR Option B) isn't built. Enabling
  # this is phase 2, alongside the OpenSearch provider / FGAC mapping (#8592).
  enable_opensearch_ingestion = local.opensearch_objects_enabled

  # TEMPORARY, for the demo only: hardcoded to one ephemeral dev cluster's bucket
  # instead of the per-workspace name above, because that bucket doesn't exist at
  # the root level. This cluster can be torn down at any time — if the demo
  # pipeline starts failing on a missing bucket, that's why. Revert to the
  # ${terraform.workspace}-fluentbit form (or the Option B cross-account design,
  # see ADR-017) once a durable answer exists. Tracked on #8419.
  opensearch_ingestion_bucket        = "cp-2010-1157-fluentbit"
  opensearch_ingestion_index         = "cp-${local.opensearch_env_label}-logs"
  opensearch_ingestion_pipeline_name = "cp-${local.opensearch_env_label}-s3-logs"
}

# Bucket is owned by the `cluster` component; look it up by name.
data "aws_s3_bucket" "opensearch_ingestion_source" {
  count  = local.enable_opensearch_ingestion ? 1 : 0
  bucket = local.opensearch_ingestion_bucket
}

resource "aws_sqs_queue" "opensearch_ingestion_dlq" {
  count = local.enable_opensearch_ingestion ? 1 : 0

  name                      = "${local.opensearch_ingestion_pipeline_name}-dlq"
  message_retention_seconds = 1209600 # 14 days
  sqs_managed_sse_enabled   = true

  tags = merge(local.tags, { component = "observability" })
}

resource "aws_sqs_queue" "opensearch_ingestion" {
  count = local.enable_opensearch_ingestion ? 1 : 0

  name                       = local.opensearch_ingestion_pipeline_name
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 300 # >= time OSIS takes to read a batch

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.opensearch_ingestion_dlq[0].arn
    maxReceiveCount     = 5
  })

  tags = merge(local.tags, { component = "observability" })
}

# prefix "logs/" is the per-consumer object filter — only app logs, not auto-mode/.
resource "aws_cloudwatch_event_rule" "opensearch_ingestion" {
  count = local.enable_opensearch_ingestion ? 1 : 0

  name        = local.opensearch_ingestion_pipeline_name
  description = "New objects under logs/ in the Fluent Bit bucket -> OpenSearch ingestion queue"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = { name = [local.opensearch_ingestion_bucket] }
      object = { key = [{ prefix = "logs/" }] }
    }
  })

  tags = merge(local.tags, { component = "observability" })
}

resource "aws_cloudwatch_event_target" "opensearch_ingestion" {
  count = local.enable_opensearch_ingestion ? 1 : 0

  rule = aws_cloudwatch_event_rule.opensearch_ingestion[0].name
  arn  = aws_sqs_queue.opensearch_ingestion[0].arn
}

# Only this EventBridge rule may send to the queue.
data "aws_iam_policy_document" "opensearch_ingestion_sqs" {
  count = local.enable_opensearch_ingestion ? 1 : 0

  statement {
    sid       = "AllowEventBridgeSendMessage"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.opensearch_ingestion[0].arn]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.opensearch_ingestion[0].arn]
    }
  }
}

resource "aws_sqs_queue_policy" "opensearch_ingestion" {
  count = local.enable_opensearch_ingestion ? 1 : 0

  queue_url = aws_sqs_queue.opensearch_ingestion[0].id
  policy    = data.aws_iam_policy_document.opensearch_ingestion_sqs[0].json
}

# OSIS pipeline role: one role reads S3 + SQS (source) and writes the domain
# (sink) — the same sts_role_arn is used in both pipeline blocks.
data "aws_iam_policy_document" "opensearch_ingestion_assume" {
  count = local.enable_opensearch_ingestion ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["osis-pipelines.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "opensearch_ingestion" {
  count = local.enable_opensearch_ingestion ? 1 : 0

  name               = "${local.opensearch_ingestion_pipeline_name}-pipeline"
  assume_role_policy = data.aws_iam_policy_document.opensearch_ingestion_assume[0].json

  tags = merge(local.tags, { component = "observability" })
}

data "aws_iam_policy_document" "opensearch_ingestion_role" {
  count = local.enable_opensearch_ingestion ? 1 : 0

  statement {
    sid    = "ReadSourceBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      data.aws_s3_bucket.opensearch_ingestion_source[0].arn,
      "${data.aws_s3_bucket.opensearch_ingestion_source[0].arn}/*",
    ]
  }

  statement {
    sid    = "ConsumeQueue"
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [aws_sqs_queue.opensearch_ingestion[0].arn]
  }

  statement {
    sid    = "WriteOpenSearch"
    effect = "Allow"
    actions = [
      "es:DescribeDomain",
      "es:ESHttpGet",
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:ESHttpHead",
    ]
    resources = [
      "arn:aws:es:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_domain_name}",
      "arn:aws:es:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_domain_name}/*",
    ]
  }
}

resource "aws_iam_role_policy" "opensearch_ingestion" {
  count = local.enable_opensearch_ingestion ? 1 : 0

  name   = "${local.opensearch_ingestion_pipeline_name}-pipeline"
  role   = aws_iam_role.opensearch_ingestion[0].id
  policy = data.aws_iam_policy_document.opensearch_ingestion_role[0].json
}

# TODO #8592: FGAC role mapping. Writes 403 until this role is mapped to a write
# role inside OpenSearch via the OpenSearch provider (not wired yet). Pipeline
# reaches ACTIVE but writes fail until then — expected.

# newline codec + parse_json: Fluent Bit writes newline-delimited JSON, one event
# per line. Index date pattern %%{...} escapes Terraform's %{} so OSIS gets %{...}.
resource "aws_osis_pipeline" "opensearch_logs" {
  count = local.enable_opensearch_ingestion ? 1 : 0

  pipeline_name = local.opensearch_ingestion_pipeline_name
  min_units     = 1 # S3-SQS (pull) allows 1; raise if the queue backs up
  max_units     = 4

  pipeline_configuration_body = yamlencode({
    version = "2"
    "log-pipeline" = {
      source = {
        s3 = {
          notification_type   = "sqs"
          notification_source = "eventbridge" # messages arrive via EventBridge, not direct S3
          codec               = { newline = null }
          compression         = "none"
          sqs                 = { queue_url = aws_sqs_queue.opensearch_ingestion[0].url }
          aws = {
            region       = data.aws_region.current.region
            sts_role_arn = aws_iam_role.opensearch_ingestion[0].arn
          }
        }
      }
      processor = [{ parse_json = null }]
      sink = [{
        opensearch = {
          hosts = ["https://${aws_opensearch_domain.logs[0].endpoint}"]
          index = "${local.opensearch_ingestion_index}-%%{yyyy.MM.dd}"
          aws = {
            region       = data.aws_region.current.region
            sts_role_arn = aws_iam_role.opensearch_ingestion[0].arn
          }
        }
      }]
    }
  })

  tags = merge(local.tags, { component = "observability" })

  depends_on = [
    aws_iam_role_policy.opensearch_ingestion,
    aws_sqs_queue_policy.opensearch_ingestion,
  ]
}

output "opensearch_ingestion_pipeline_name" {
  description = "OSIS pipeline name (null when ingestion not enabled)."
  value       = local.enable_opensearch_ingestion ? aws_osis_pipeline.opensearch_logs[0].pipeline_name : null
}
