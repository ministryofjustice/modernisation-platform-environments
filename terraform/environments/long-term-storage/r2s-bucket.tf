############################################################
# Inputs 
############################################################

variable "secrets_populated" {
  description = "Flip to true only after you've populated all Secrets Manager values. If rebuilding it will need to be false first"
  type        = bool
  default     = true
}

############################################################
# Locals for this bucket setup
############################################################

locals {
  # Ensure global uniqueness to avoid BucketAlreadyExists
  bucket_name = "r2s-resources-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}"

  # Read base secrets only when populated; stay null otherwise (prevents eval errors)
  genesys_aws_account_id         = var.secrets_populated ? try(nonsensitive(data.aws_secretsmanager_secret_version.genesys_account_id[0].secret_string), null) : null
  genesys_external_id            = var.secrets_populated ? try(nonsensitive(data.aws_secretsmanager_secret_version.genesys_external_id[0].secret_string), null) : null
  snowflake_principal_account_id = var.secrets_populated ? try(nonsensitive(data.aws_secretsmanager_secret_version.snowflake_principal_account_id[0].secret_string), null) : null
  snowflake_external_id          = var.secrets_populated ? try(nonsensitive(data.aws_secretsmanager_secret_version.snowflake_external_id[0].secret_string), null) : null

  snowflake_prefix = "metadata/"

  # Define Genesys roles (no literal prefixes; fetch from Secrets Manager)
  genesys_roles = {
    role1 = { name = "r2s-genesys-cica-role",             prefix_key = "cica" }
    role2 = { name = "r2s-genesys-opg-role",              prefix_key = "opg" }
    role3 = { name = "r2s-genesys-laa-role",              prefix_key = "laa" }
    role4 = { name = "r2s-genesys-hmpps-role",            prefix_key = "hmpps" }
    role5 = { name = "r2s-genesys-london-probation-role", prefix_key = "london-probation" }
    role6 = { name = "r2s-genesys-nle-role",              prefix_key = "nle" }
  }

  # Map role key -> full secret name "<prefix>_ou"
  genesys_prefix_secret_name = {
    for k, v in local.genesys_roles :
    k => "r2s/genesys/prefixes/${v.prefix_key}_ou"
  }

  # Build a map role -> normalized prefix (trailing slash); null if not populated
  genesys_prefix = {
    for k in keys(local.genesys_roles) :
    k => (
      var.secrets_populated
      ? "${trimsuffix(try(nonsensitive(data.aws_secretsmanager_secret_version.genesys_prefix[k].secret_string), ""), "/")}/"
      : null
    )
  }

  # Simple, predictable gates: depend ONLY on the toggle
  genesys_ready   = var.secrets_populated
  snowflake_ready = var.secrets_populated
}

############################################################
# S3 bucket + hardening
############################################################

resource "aws_s3_bucket" "r2s" {
  # checkov:skip=CKV_AWS_145: "S3 bucket is not public facing
  # checkov:skip=CKV_AWS_18:"Access logging not required"
  # checkov:skip=CKV2_AWS_62:"Event notifications not required for this bucket"
  # checkov:skip=CKV_AWS_21:Versioning not needed
  # checkov:skip=CKV_AWS_144:"Cross-region replication not required"
  # checkov:skip=CKV2_AWS_65:"ACLs are required by design"
  # checkov:skip=CKV2_AWS_61:"Lifecycle configuration not specified"
  bucket = local.bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "r2s" {
  bucket                  = aws_s3_bucket.r2s.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "r2s" {
  # checkov:skip=CKV2_AWS_65:"ACLs are required by design"
  bucket = aws_s3_bucket.r2s.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "r2s" {
  #tfsec:ignore:avd-aws-0132 - The bucket policy is attached to the bucket  
  bucket = aws_s3_bucket.r2s.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Deny insecure (non-TLS) access
data "aws_iam_policy_document" "r2s_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [
      aws_s3_bucket.r2s.arn,
      "${aws_s3_bucket.r2s.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "r2s" {
  bucket = aws_s3_bucket.r2s.id
  policy = data.aws_iam_policy_document.r2s_tls_only.json
}

############################################################
# S3 "folders" 
############################################################

# Create one folder per Genesys prefix secret
resource "aws_s3_object" "genesys_folders" {
  # only when secrets are populated, and ignore empty values
  for_each = var.secrets_populated ? {
    for k, v in local.genesys_prefix : k => v if v != null && v != "/"
  } : {}

  bucket  = aws_s3_bucket.r2s.id
  key     = each.value                 # e.g. "cica/" (we normalized with trailing slash)
  content = ""                         # zero-byte marker object
  server_side_encryption = "AES256"
}

# Optional: ensure the Snowflake metadata/ prefix exists too
resource "aws_s3_object" "snowflake_folder" {
  count   = 1
  bucket  = aws_s3_bucket.r2s.id
  key     = local.snowflake_prefix     # "metadata/"
  content = ""
  server_side_encryption = "AES256"
}


############################################################
# Secrets Manager: create empty secrets (populate in console)
############################################################

# Create 6 empty secrets for the prefixes (<prefix>_ou)
resource "aws_secretsmanager_secret" "genesys_prefix" {
  # checkov:skip=CKV_AWS_149
  # checkov:skip=CKV2_AWS_57
  for_each    = local.genesys_roles
  name        = local.genesys_prefix_secret_name[each.key]
  description = "S3 prefix (folder) for ${each.value.name}. Example value: '${each.value.prefix_key}/'"
  tags        = local.tags
}

resource "aws_secretsmanager_secret" "genesys_account_id" {
  # checkov:skip=CKV_AWS_149
  # checkov:skip=CKV2_AWS_57
  name        = "r2s/genesys/aws_account_id"
  description = "Genesys Cloud AWS Account ID (populate manually)."
  tags        = local.tags
}

resource "aws_secretsmanager_secret" "genesys_external_id" {
  # checkov:skip=CKV_AWS_149
  # checkov:skip=CKV2_AWS_57
  name        = "r2s/genesys/external_id"
  description = "Genesys Cloud Org ID used as ExternalId (populate manually)."
  tags        = local.tags
}

resource "aws_secretsmanager_secret" "snowflake_principal_account_id" {
  # checkov:skip=CKV_AWS_149
  # checkov:skip=CKV2_AWS_57
  name        = "r2s/snowflake/principal_account_id"
  description = "Snowflake AWS Account ID (populate manually)."
  tags        = local.tags
}

resource "aws_secretsmanager_secret" "snowflake_external_id" {
  # checkov:skip=CKV_AWS_149
  # checkov:skip=CKV2_AWS_57
  name        = "r2s/snowflake/external_id"
  description = "Snowflake External ID (populate manually)."
  tags        = local.tags
}

# --- Read the latest secret values (only when flagged as populated) ---

# Genesys prefix secrets (all six) — single reader with for_each
data "aws_secretsmanager_secret_version" "genesys_prefix" {
  for_each = var.secrets_populated ? local.genesys_roles : {}
  secret_id = aws_secretsmanager_secret.genesys_prefix[each.key].id
}
# Other 4 are not created with a for each
data "aws_secretsmanager_secret_version" "genesys_account_id" {
  count     = var.secrets_populated ? 1 : 0
  secret_id = aws_secretsmanager_secret.genesys_account_id.id
}

data "aws_secretsmanager_secret_version" "genesys_external_id" {
  count     = var.secrets_populated ? 1 : 0
  secret_id = aws_secretsmanager_secret.genesys_external_id.id
}

data "aws_secretsmanager_secret_version" "snowflake_principal_account_id" {
  count     = var.secrets_populated ? 1 : 0
  secret_id = aws_secretsmanager_secret.snowflake_principal_account_id.id
}

data "aws_secretsmanager_secret_version" "snowflake_external_id" {
  count     = var.secrets_populated ? 1 : 0
  secret_id = aws_secretsmanager_secret.snowflake_external_id.id
}

############################################################
# IAM: Genesys trust + 6 roles + per-prefix policies
############################################################

# Trust policy for Genesys (only rendered when populated)
data "aws_iam_policy_document" "genesys_trust" {
  count = var.secrets_populated ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.genesys_aws_account_id}:root"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [local.genesys_external_id]
    }
  }
}

# Create 6 roles 
resource "aws_iam_role" "genesys_role" {
  for_each = local.genesys_ready ? local.genesys_roles : {}

  name               = each.value.name
  assume_role_policy = one(data.aws_iam_policy_document.genesys_trust[*].json)
  description        = "Role assumed by Genesys Cloud export module to upload recordings to ${local.bucket_name} in ${local.genesys_prefix[each.key]}"
  tags               = local.tags
}

# S3 policy document restricted to its own prefix
data "aws_iam_policy_document" "genesys_prefix" {
  for_each = local.genesys_ready ? local.genesys_roles : {}

  # List only within the specific prefix
  statement {
    sid     = "ListBucketWithinPrefix"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.r2s.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.genesys_prefix[each.key]}*"]
    }
  }

  # Object access only inside the folder
  statement {
    sid    = "ObjectAccessInPrefix"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}/${local.genesys_prefix[each.key]}*"
    ]
  }

  # Bucket metadata reads
  statement {
    sid     = "BucketMetadata"
    effect  = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration"
    ]
    resources = [aws_s3_bucket.r2s.arn]
  }
}

# Managed policy per role
resource "aws_iam_policy" "genesys_prefix" {
  for_each = data.aws_iam_policy_document.genesys_prefix

  name        = "r2s-genesys-prefix-${each.key}"
  description = "Restrict ${local.genesys_roles[each.key].name} to s3://${local.bucket_name}/${local.genesys_prefix[each.key]}"
  policy      = each.value.json
  tags        = local.tags
}

# Attach the restricted policy to the matching role
resource "aws_iam_role_policy_attachment" "genesys_prefix_attach" {
  for_each = local.genesys_ready ? local.genesys_roles : {}

  role       = aws_iam_role.genesys_role[each.key].name
  policy_arn = aws_iam_policy.genesys_prefix[each.key].arn
}

############################################################
# IAM: Snowflake trust + policy (metadata-only) + role
############################################################

# Trust policy for Snowflake (only rendered when populated)
data "aws_iam_policy_document" "snowflake_trust" {
  count = var.secrets_populated ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.snowflake_principal_account_id}:root"]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [local.snowflake_external_id]
    }
  }
}


# Snowflake policy: metadata-only prefix (can be created regardless)
data "aws_iam_policy_document" "snowflake_policy_doc" {
  statement {
    sid     = "ListBucketMetadataPrefix"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.r2s.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.snowflake_prefix}*"]
    }
  }

  statement {
    sid    = "ObjectAccessInMetadataPrefix"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:DeleteObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}/${local.snowflake_prefix}*"
    ]
  }

  statement {
    sid     = "BucketMetadata"
    effect  = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetEncryptionConfiguration"
    ]
    resources = [aws_s3_bucket.r2s.arn]
  }
}

resource "aws_iam_policy" "snowflake_policy" {
  name        = "r2s-snowflake-metadata-only"
  description = "Allow Snowflake to access metadata objects only in s3://${local.bucket_name}/${local.snowflake_prefix}"
  policy      = data.aws_iam_policy_document.snowflake_policy_doc.json
  tags        = local.tags
}

resource "aws_iam_role" "snowflake_role" {
  for_each           = local.snowflake_ready ? { main = true } : {}
  name               = "r2s-snowflake-role"
  assume_role_policy = one(data.aws_iam_policy_document.snowflake_trust[*].json)
  description        = "Role for Snowflake to process metadata in ${local.bucket_name} (no access to recordings)."
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "snowflake_attach" {
  for_each  = local.snowflake_ready ? { main = true } : {}
  role       = aws_iam_role.snowflake_role["main"].name
  policy_arn = aws_iam_policy.snowflake_policy.arn
}
