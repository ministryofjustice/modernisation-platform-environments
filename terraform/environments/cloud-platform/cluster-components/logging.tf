data "aws_s3_bucket" "fluent_bit" {
  bucket = "${terraform.workspace}-fluentbit"
}

data "aws_opensearch_domain" "fluent_bit" {
  domain_name = "cp-development-logs"
}

locals {
  fluent_bit_namespace       = "logging"
  fluent_bit_service_account = "fluent-bit"
  fluent_bit_state_dir       = "/var/fluent-bit/state"
}

#------------------------------------------------------------------------------
# IAM role for Fluent Bit (EKS Pod Identity) — S3, CloudWatch Logs and OpenSearch
#------------------------------------------------------------------------------

data "aws_iam_policy_document" "fluent_bit_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fluent_bit" {
  name               = "${local.cluster_name}-fluent-bit"
  assume_role_policy = data.aws_iam_policy_document.fluent_bit_assume.json

  tags = local.tags
}

data "aws_iam_policy_document" "fluent_bit_logs" {
  statement {
    sid       = "WriteS3Logs"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${data.aws_s3_bucket.fluent_bit.arn}/logs/*"]
  }

  statement {
    sid    = "WriteCloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy",
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${terraform.workspace}/fluentbit/*"]
  }

  statement {
    sid       = "WriteOpenSearchLogs"
    effect    = "Allow"
    actions   = ["es:ESHttpPost"]
    resources = ["${data.aws_opensearch_domain.fluent_bit.arn}/_bulk"]
  }
}

resource "aws_iam_role_policy" "fluent_bit_logs" {
  name   = "fluent-bit-log-write"
  role   = aws_iam_role.fluent_bit.id
  policy = data.aws_iam_policy_document.fluent_bit_logs.json
}

resource "opensearch_role" "fluent_bit" {
  role_name = "fluentbit-${terraform.workspace}-writer"

  cluster_permissions = ["indices:data/write/bulk"]

  index_permissions {
    index_patterns  = ["${terraform.workspace}-*"]
    allowed_actions = ["write", "create_index"]
  }
}

resource "opensearch_roles_mapping" "fluent_bit" {
  role_name     = opensearch_role.fluent_bit.role_name
  backend_roles = [aws_iam_role.fluent_bit.arn]
}

moved {
  from = aws_iam_role_policy.fluent_bit_s3
  to   = aws_iam_role_policy.fluent_bit_logs
}

resource "aws_eks_pod_identity_association" "fluent_bit" {
  cluster_name    = local.cluster_name
  namespace       = local.fluent_bit_namespace
  service_account = local.fluent_bit_service_account
  role_arn        = aws_iam_role.fluent_bit.arn

  tags = local.tags
}

resource "time_sleep" "fluent_bit_pod_identity" {
  create_duration = "30s"
  triggers = {
    association_id = aws_eks_pod_identity_association.fluent_bit.id
  }

  depends_on = [aws_eks_pod_identity_association.fluent_bit]
}

#------------------------------------------------------------------------------
# Namespace — privileged PSA is required for the hostPath mounts of /var/log
#------------------------------------------------------------------------------

resource "kubernetes_namespace_v1" "logging" {
  metadata {
    name = local.fluent_bit_namespace

    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

#------------------------------------------------------------------------------
# Fluent Bit DaemonSet — ships container logs to S3, CloudWatch and OpenSearch
#------------------------------------------------------------------------------

resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.54.0"
  namespace  = kubernetes_namespace_v1.logging.metadata[0].name

  values = [yamlencode({
    serviceAccount = {
      create = true
      name   = local.fluent_bit_service_account
    }

    podAnnotations = {
      "platform.justice.gov.uk/pod-identity-association" = "${aws_eks_pod_identity_association.fluent_bit.id}-${time_sleep.fluent_bit_pod_identity.id}"
    }

    # Required by the Gatekeeper lockprivcapabilities constraint
    securityContext = {
      capabilities = {
        drop = ["ALL"]
      }
    }

    tolerations = [{ operator = "Exists" }]

    # Host-backed buffer so queued chunks and pending S3 uploads survive pod restarts
    extraVolumes = [{
      name = "fluent-bit-state"
      hostPath = {
        path = local.fluent_bit_state_dir
        type = "DirectoryOrCreate"
      }
    }]

    extraVolumeMounts = [{
      name      = "fluent-bit-state"
      mountPath = local.fluent_bit_state_dir
    }]

    luaScripts = {
      "normalize-duration.lua" = <<-LUA
      local milliseconds_per_unit = {
        ns = 0.000001,
        us = 0.001,
        ms = 1,
        s = 1000,
        m = 60000,
        h = 3600000
      }

      local function parse_duration(value)
        local remaining = value:lower():match("^%s*(.-)%s*$")
        local numeric = tonumber(remaining)
        if numeric then
          return numeric
        end

        local sign = 1
        if remaining:sub(1, 1) == "-" then
          sign = -1
          remaining = remaining:sub(2)
        elseif remaining:sub(1, 1) == "+" then
          remaining = remaining:sub(2)
        end

        local total = 0
        if remaining == "" then
          return nil
        end
        while remaining ~= "" do
                local amount, unit, suffix = remaining:match("^(%d*%.?%d+)%s*([a-z]+)%s*(.*)$")
          if not amount or not milliseconds_per_unit[unit] then
            return nil
          end
          total = total + tonumber(amount) * milliseconds_per_unit[unit]
          remaining = suffix
        end
            return sign * total
      end

      function normalize_duration(tag, timestamp, record)
        local original = record["duration"]
        if original == nil then
          return 0, timestamp, record
        end

        local normalized = nil
        if type(original) == "number" then
          normalized = original
        elseif type(original) == "string" then
          record["duration_raw"] = original
          normalized = parse_duration(original)
        else
          record["duration_raw"] = tostring(original)
        end

        if normalized and (normalized ~= normalized or math.abs(normalized) == math.huge) then
          normalized = nil
        end
        record["duration"] = normalized
        return 2, timestamp, record
      end
      LUA
    }

    config = {
      service = <<-EOT
        [SERVICE]
            Daemon                    Off
            Flush                     1
            Log_Level                 info
            Parsers_File              /fluent-bit/etc/parsers.conf
            Parsers_File              /fluent-bit/etc/conf/custom_parsers.conf
            HTTP_Server               On
            HTTP_Listen               0.0.0.0
            HTTP_Port                 2020
            Health_Check              On
            storage.path              ${local.fluent_bit_state_dir}/flb-storage/
            storage.sync              normal
            storage.checksum          off
            storage.max_chunks_up     128
            storage.backlog.mem_limit 50M
      EOT

      inputs = <<-EOT
        [INPUT]
            Name              tail
            Tag               kube.*
            Path              /var/log/containers/*.log
            Exclude_Path      /var/log/containers/fluent-bit*
            multiline.parser  cri, docker
            DB                ${local.fluent_bit_state_dir}/flb_kube.db
            storage.type      filesystem
            Skip_Long_Lines   On
            Refresh_Interval  10
      EOT

      filters = <<-EOT
        [FILTER]
            Name                kubernetes
            Match               kube.*
            Merge_Log           On
            Keep_Log            Off
            K8S-Logging.Parser  On
            K8S-Logging.Exclude On

        [FILTER]
            Name    lua
            Match   kube.*
            script  /fluent-bit/scripts/normalize-duration.lua
            call    normalize_duration

        [FILTER]
            Name    record_modifier
            Match   kube.*
            Record  cluster_name ${local.cluster_name}

        # Re-tag as ns.<namespace> so the S3 key can be partitioned by namespace
        [FILTER]
            Name                    rewrite_tag
            Match                   kube.*
            Rule                    $kubernetes['namespace_name'] ^(.+)$ ns.$1 true
            Emitter_Name            ns_emitter
            Emitter_Storage.type    filesystem
            Emitter_Mem_Buf_Limit   50M
      EOT

      outputs = <<-EOT
        [OUTPUT]
            Name                     s3
            Match                    ns.*
            bucket                   ${data.aws_s3_bucket.fluent_bit.id}
            region                   ${data.aws_region.current.region}
            s3_key_format            /logs/$TAG[1]/%Y/%m/%d/%H/%M%S-$UUID.gz
            compression              gzip
            use_put_object           On
            total_file_size          50M
            upload_timeout           10m
            store_dir                ${local.fluent_bit_state_dir}/s3
            store_dir_limit_size     2G
            storage.total_limit_size 2G

        [OUTPUT]
            Name                cloudwatch_logs
            Match               kube.*
            Region              ${data.aws_region.current.region}
            Log_Group_Name      /aws/eks/${terraform.workspace}/fluentbit/fallback
            Log_Stream_Prefix   from-fluent-bit-
            Log_Group_Template  /aws/eks/${terraform.workspace}/fluentbit/$kubernetes['namespace_name']
            Log_Stream_Template $kubernetes['pod_name'].$kubernetes['container_name']
            Auto_Create_Group   On
            Log_Retention_Days  30
            Retry_Limit         False
            storage.total_limit_size 2G

        [OUTPUT]
            Name                     opensearch
            Match                    kube.*
            Host                     ${data.aws_opensearch_domain.fluent_bit.endpoint}
            Port                     443
            TLS                      On
            TLS.Verify               On
            AWS_Auth                 On
            AWS_Region               eu-west-2
            Logstash_Format          On
            Logstash_Prefix          ${terraform.workspace}
            Replace_Dots             On
            Suppress_Type_Name       On
            Generate_ID              On
            Retry_Limit              False
            storage.total_limit_size 2G
      EOT
    }
  })]

  depends_on = [
    time_sleep.fluent_bit_pod_identity,
    aws_iam_role_policy.fluent_bit_logs,
    opensearch_roles_mapping.fluent_bit,
  ]
}