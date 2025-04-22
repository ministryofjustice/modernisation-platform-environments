resource "aws_security_group" "ingestion_lb" {
  description = "Security group for ingestion load balancer, to do server certificate auth with Xhibit"
  name        = "ingestion-loadbalancer-${var.networking[0].application}"
  vpc_id      = local.vpc_id
}

# resource "aws_security_group_rule" "egress-to-ingestion" {
#   depends_on               = [aws_security_group.ingestion_lb]
#   security_group_id        = aws_security_group.ingestion_lb.id
#   type                     = "egress"
#   description              = "allow web traffic to get to ingestion server"
#   from_port                = 80
#   to_port                  = 80
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.ingestion_server.id
# }

resource "aws_security_group_rule" "ingestion_lb_allow_web_users" {
  depends_on        = [aws_security_group.ingestion_lb]
  security_group_id = aws_security_group.ingestion_lb.id
  type              = "ingress"
  description       = "allow web traffic to get to ingestion server"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks = [
    "10.182.60.51/32",   # NLE CGI proxy
    "80.195.27.199/32",  # Appsec-CJSE - Krupal ITHC
    "195.59.75.151/32",  # New proxy IPs from Prashanth for testing ingestion NLE DEV
    "195.59.75.152/32",  # New proxy IPs from Prashanth for testing ingestion NLE DEV
    "194.33.192.0/24",   # New proxy IPs from Prashanth for testing ingestion LE PROD
    "194.33.196.0/24",   # New proxy IPs from Prashanth for testing ingestion LE PROD
    "194.33.248.0/24",   # New proxy IPs from Prashanth for testing ingestion LE PROD
    "194.33.249.0/24",   # New proxy IPs from Prashanth for testing ingestion LE PROD
    "195.206.176.96/27", # New proxy IPs from Prashanth for testing ingestion LE PRE
    "195.206.178.96/27"  # New proxy IPs from Prashanth for testing ingestion LE PRE
  ]
  ipv6_cidr_blocks = [
    "2a00:23c7:2416:3d01:c98d:4432:3c83:d937/128"
  ]
}

data "aws_subnets" "ingestion-shared-public" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  tags = {
    "Name" = "${var.networking[0].business-unit}-${local.environment}-${var.networking[0].set}-public*"
  }
}

# trivy:ignore:AVD-AWS-0053 reason: (HIGH): Load balancer is exposed publicly.
resource "aws_elb" "ingestion_lb" {

  # checkov:skip=CKV_AWS_376: "Ensure AWS Elastic Load Balancer listener uses TLS/SSL"

  depends_on = [
    aws_security_group.ingestion_lb,
  ]

  name            = "ingestion-lb-${var.networking[0].application}"
  internal        = false
  security_groups = [aws_security_group.ingestion_lb.id]
  subnets         = data.aws_subnets.ingestion-shared-public.ids

  access_logs {
    bucket        = aws_s3_bucket.loadbalancer_logs.bucket
    bucket_prefix = "http-lb"
    enabled       = true
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = data.aws_acm_certificate.ingestion_lb_cert.arn
  }

  health_check {
    healthy_threshold   = 6
    unhealthy_threshold = 2
    timeout             = 2
    target              = "HTTP:80/"
    interval            = 5
  }

  instances                   = [aws_instance.cjip-server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = merge(
    local.tags,
    {
      Name = "ingestion-lb-${var.networking[0].application}"
    },
  )
}

data "aws_acm_certificate" "ingestion_lb_cert" {
  domain   = local.application_data.accounts[local.environment].public_dns_name_ingestion
  statuses = ["ISSUED"]
}

# trivy:ignore:AVD-AWS-0086 reason: (HIGH): No public access block so not blocking public acls
# trivy:ignore:AVD-AWS-0087 reason: (HIGH): No public access block so not blocking public policies
# trivy:ignore:AVD-AWS-0091 reason: (HIGH): No public access block so not blocking public acls
# trivy:ignore:AVD-AWS-0093 reason: (HIGH): No public access block so not restricting public buckets
resource "aws_s3_bucket" "ingestion_loadbalancer_logs" {
  # checkov:skip=CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
  # checkov:skip=CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
  # checkov:skip=CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
  # checkov:skip=CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
  # checkov:skip=CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
  # checkov:skip=CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
  # checkov:skip=CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
  bucket        = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}-ingestion-lblogs"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "ingestion_loadbalancer_logs" {
  bucket = aws_s3_bucket.ingestion_loadbalancer_logs.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default_encryption_ingestion_loadbalancer_logs" {
  bucket = aws_s3_bucket.ingestion_loadbalancer_logs.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "ingestion_loadbalancer_logs_policy" {
  bucket = aws_s3_bucket.ingestion_loadbalancer_logs.bucket
  policy = data.aws_iam_policy_document.s3_bucket_ingestion_lb_write.json
}


data "aws_iam_policy_document" "s3_bucket_ingestion_lb_write" {

  statement {
    sid = "AllowSSLRequestsOnly"
    actions = [
      "s3:*",
    ]
    effect = "Deny"
    resources = [
      "${aws_s3_bucket.ingestion_loadbalancer_logs.arn}/*",
      aws_s3_bucket.ingestion_loadbalancer_logs.arn
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }

  statement {
    actions = [
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.ingestion_loadbalancer_logs.arn}/*",
    ]

    principals {
      identifiers = ["arn:aws:iam::652711504416:root"]
      type        = "AWS"
    }
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.ingestion_loadbalancer_logs.arn}/*"]

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    actions = [
      "s3:GetBucketAcl"
    ]
    effect    = "Allow"
    resources = [aws_s3_bucket.ingestion_loadbalancer_logs.arn]

    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_load_balancer_policy" "ingestion-ssl" {

  # checkov:skip=CKV_AWS_213: "Ensure ELB Policy uses only secure protocols"

  load_balancer_name = aws_elb.ingestion_lb.name
  policy_name        = "ingestion-lb-ssl"
  policy_type_name   = "SSLNegotiationPolicyType"

  policy_attribute {
    name  = "Protocol-TLSv1"
    value = "true"
  }

  policy_attribute {
    name  = "Protocol-SSLv3"
    value = "true"
  }

  policy_attribute {
    name  = "Protocol-TLSv1.1"
    value = "true"
  }

  policy_attribute {
    name  = "Protocol-TLSv1.2"
    value = "true"
  }

  policy_attribute {
    name  = "Server-Defined-Cipher-Order"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-EDH-DSS-DES-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-ECDSA-AES128-GCM-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-RSA-AES128-GCM-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-ECDSA-AES128-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-RSA-AES128-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-ECDSA-AES128-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-RSA-AES128-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-ECDSA-AES256-GCM-SHA384"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-RSA-AES256-GCM-SHA384"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-ECDSA-AES256-SHA384"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-RSA-AES256-SHA384"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-RSA-AES256-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-ECDSA-AES256-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "AES128-GCM-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "AES128-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "AES128-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "AES256-GCM-SHA384"
    value = "true"
  }

  policy_attribute {
    name  = "AES256-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "AES256-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-DSS-AES128-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "CAMELLIA128-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "EDH-RSA-DES-CBC3-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DES-CBC3-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-RSA-RC4-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "RC4-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ECDHE-ECDSA-RC4-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-DSS-AES256-GCM-SHA384"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-RSA-AES256-GCM-SHA384"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-RSA-AES256-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-DSS-AES256-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-RSA-AES256-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-DSS-AES256-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-RSA-CAMELLIA256-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-DSS-CAMELLIA256-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "CAMELLIA256-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "EDH-DSS-DES-CBC3-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-DSS-AES128-GCM-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-RSA-AES128-GCM-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-RSA-AES128-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-DSS-AES128-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-RSA-CAMELLIA128-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-DSS-CAMELLIA128-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-AES128-GCM-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-AES128-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-AES128-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-AES256-GCM-SHA384"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-AES256-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-AES256-SHA256"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-CAMELLIA128-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-CAMELLIA256-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-DES-CBC3-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-DES-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-RC4-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "ADH-SEED-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DES-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-DSS-SEED-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-RSA-SEED-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "EDH-DSS-DES-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "EDH-RSA-DES-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "IDEA-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "RC4-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "SEED-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DES-CBC3-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "DES-CBC-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "RC2-CBC-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "PSK-AES256-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "PSK-3DES-EDE-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "KRB5-DES-CBC3-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "KRB5-DES-CBC3-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "PSK-AES128-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "PSK-RC4-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "KRB5-RC4-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "KRB5-RC4-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "KRB5-DES-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "KRB5-DES-CBC-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-EDH-RSA-DES-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-EDH-RSA-DES-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "DHE-RSA-AES128-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-ADH-DES-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-DES-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-RC2-CBC-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-KRB5-RC2-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-KRB5-DES-CBC-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-KRB5-RC2-CBC-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-KRB5-DES-CBC-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-ADH-RC4-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-RC4-MD5"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-KRB5-RC4-SHA"
    value = "true"
  }

  policy_attribute {
    name  = "EXP-KRB5-RC4-MD5"
    value = "true"
  }

}

resource "aws_load_balancer_listener_policy" "ingestion-listener-policies" {
  load_balancer_name = aws_elb.ingestion_lb.name
  load_balancer_port = 443

  policy_names = [
    aws_load_balancer_policy.ingestion-ssl.policy_name,
  ]
}
