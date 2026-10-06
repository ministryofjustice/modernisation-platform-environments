data "aws_s3_bucket" "fluent_bit" {
  bucket = "${terraform.workspace}-fluentbit"
}

locals {
  fluent_bit_namespace       = "logging"
  fluent_bit_service_account = "fluent-bit"
  fluent_bit_state_dir       = "/var/fluent-bit/state"
}

#------------------------------------------------------------------------------
# IAM role for Fluent Bit (EKS Pod Identity) — write-only to logs/ prefix
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

data "aws_iam_policy_document" "fluent_bit_s3" {
  statement {
    sid       = "WriteLogs"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${data.aws_s3_bucket.fluent_bit.arn}/logs/*"]
  }
}

resource "aws_iam_role_policy" "fluent_bit_s3" {
  name   = "fluent-bit-s3-write"
  role   = aws_iam_role.fluent_bit.id
  policy = data.aws_iam_policy_document.fluent_bit_s3.json
}

resource "aws_eks_pod_identity_association" "fluent_bit" {
  cluster_name    = local.cluster_name
  namespace       = local.fluent_bit_namespace
  service_account = local.fluent_bit_service_account
  role_arn        = aws_iam_role.fluent_bit.arn

  tags = local.tags
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
# Fluent Bit DaemonSet — tails container logs and ships them to S3
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
            Name    record_modifier
            Match   kube.*
            Record  cluster_name ${local.cluster_name}

        # Re-tag as ns.<namespace> so the S3 key can be partitioned by namespace
        [FILTER]
            Name                    rewrite_tag
            Match                   kube.*
            Rule                    $kubernetes['namespace_name'] ^(.+)$ ns.$1 false
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
            upload_timeout           5m
            store_dir                ${local.fluent_bit_state_dir}/s3
            store_dir_limit_size     2G
            storage.total_limit_size 2G
      EOT
    }
  })]

  depends_on = [aws_eks_pod_identity_association.fluent_bit]
}