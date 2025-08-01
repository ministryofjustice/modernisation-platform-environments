# ------------------------------------------
# output_file_structure_as_json_from_zip
# ------------------------------------------

resource "aws_iam_role" "extract_metadata_from_atrium_unstructured" {
  name               = "extract_metadata_from_atrium_unstructured"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "extract_metadata_from_atrium_unstructured_s3_policy_document" {
  statement {
    sid    = "S3PermissionsForZipFileRetrieval"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${module.s3-data-bucket.bucket.arn}/*",
      module.s3-data-bucket.bucket.arn
    ]
  }
  statement {
    sid    = "S3PermissionsForPlacingJsonInAnotherBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${module.s3-json-directory-structure-bucket.bucket.arn}/*",
      module.s3-json-directory-structure-bucket.bucket.arn
    ]
  }
}

resource "aws_iam_policy" "extract_metadata_from_atrium_unstructured_s3_policy" {
  name        = "extract-metadata-from-atrium-unstructured-lambda-s3-policy"
  description = "Policy for Lambda to use S3 for extract_metadata_from_atrium_unstructured"
  policy      = data.aws_iam_policy_document.extract_metadata_from_atrium_unstructured_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "extract_metadata_from_atrium_unstructured_s3_policy_attachment" {
  role       = aws_iam_role.extract_metadata_from_atrium_unstructured.name
  policy_arn = aws_iam_policy.extract_metadata_from_atrium_unstructured_s3_policy.arn
}

resource "aws_lambda_permission" "s3_allow_output_file_structure_as_json_from_zip" {
  statement_id  = "AllowOutputFileStructureAsJsonFromZipExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.output_file_structure_as_json_from_zip.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-data-bucket.bucket.arn
}


# ------------------------------------------
# load table from json to athena
# ------------------------------------------

resource "aws_iam_role" "load_json_table" {
  name               = "load_json_table"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "load_json_table_s3_policy_document" {
  statement {
    sid    = "S3PermissionsForLoadingJsonTable"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:GetObjectAttributes",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${module.s3-json-directory-structure-bucket.bucket.arn}/*",
      module.s3-json-directory-structure-bucket.bucket.arn,
      "${module.s3-athena-bucket.bucket.arn}/*",
      module.s3-athena-bucket.bucket.arn,
      module.s3-metadata-bucket.bucket.arn,
      "${module.s3-metadata-bucket.bucket.arn}/*",
    ]
  }
  statement {
    sid    = "AthenaPermissionsForLoadingJsonTable"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:${data.aws_region.current.name}:${local.env_account_id}:*/*"
    ]
  }
  statement {
    sid    = "GluePermissionsForLoadingJsonTable"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:UpdateTable"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:schema/*",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:table/*/*",
      "arn:aws:glue:${data.aws_region.current.name}:${local.env_account_id}:database/*"
    ]
  }
  statement {
    sid    = "SecretGetSlackKey"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecrets",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = ["arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:dlt-slack-test/*"]
  }
}

resource "aws_iam_policy" "load_json_table" {
  name        = "load-json-table-s3-policy"
  description = "Policy for Lambda to use S3 for lambda"
  policy      = data.aws_iam_policy_document.load_json_table_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "load_json_table_s3_policy_policy_attachment" {
  role       = aws_iam_role.load_json_table.name
  policy_arn = aws_iam_policy.load_json_table.arn
}

# ------------------------------------------
# unzip file
# ------------------------------------------

resource "aws_iam_role" "unzip_single_file" {
  name               = "unzip_single_file"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "place_unzipped_file_s3_policy_document" {
  statement {
    sid    = "S3PermissionsForDumpingUnzippedFile"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]
    resources = [
      "${module.s3-unzipped-files-bucket.bucket.arn}/*",
      module.s3-unzipped-files-bucket.bucket.arn,
    ]
  }
}

data "aws_iam_policy_document" "get_zip_file_s3_policy_document" {
  statement {
    sid    = "S3PermissionsForGettingZipFile"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAttributes",
    ]
    resources = [
      "${module.s3-data-bucket.bucket.arn}/*.zip",
    ]
  }
}

data "aws_iam_policy_document" "list_data_store_bucket_s3_policy_document" {
  statement {
    sid    = "S3PermissionsForListingDataStore"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = [
      module.s3-data-bucket.bucket.arn,
    ]
  }
}

resource "aws_iam_policy" "get_zip_file_s3" {
  name        = "get-zip-file-s3-policy"
  description = "Policy for Lambda to get zip file from S3"
  policy      = data.aws_iam_policy_document.get_zip_file_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "get_zip_file_s3_policy_policy_attachment" {
  role       = aws_iam_role.unzip_single_file.name
  policy_arn = aws_iam_policy.get_zip_file_s3.arn
}

resource "aws_iam_policy" "list_data_store_bucket" {
  name        = "list-data-store-bucket-policy"
  description = "Policy for Lambda to list the data store S3 bucket"
  policy      = data.aws_iam_policy_document.list_data_store_bucket_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "list_data_store_bucket_policy_policy_attachment" {
  role       = aws_iam_role.unzip_single_file.name
  policy_arn = aws_iam_policy.list_data_store_bucket.arn
}


resource "aws_iam_policy" "place_unzip_single_file" {
  name        = "place-unzip-single-file-s3-policy"
  description = "Policy for Lambda to use S3 for lambda"
  policy      = data.aws_iam_policy_document.place_unzipped_file_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "place_unzip_single_file_s3_policy_policy_attachment" {
  role       = aws_iam_role.unzip_single_file.name
  policy_arn = aws_iam_policy.place_unzip_single_file.arn
}

# ----------------------------
# unzipped_presigned_url
# ----------------------------

resource "aws_iam_role" "unzipped_presigned_url" {
  name               = "unzipped_presigned_url"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "get_unzipped_presigned_url_file_s3_policy_document" {
  statement {
    sid    = "S3PermissionsForDumpingUnzippedFile"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "${module.s3-unzipped-files-bucket.bucket.arn}/*",
      module.s3-unzipped-files-bucket.bucket.arn,
    ]
  }
}


resource "aws_iam_policy" "unzipped_presigned_url_s3" {
  name        = "unzipped-presigned-url-s3-policy"
  description = "Policy for Lambda to create presigned url for unzipped file from S3"
  policy      = data.aws_iam_policy_document.get_unzipped_presigned_url_file_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "unzipped_presigned_url_s3_policy_policy_attachment" {
  role       = aws_iam_role.unzipped_presigned_url.name
  policy_arn = aws_iam_policy.unzipped_presigned_url_s3.arn
}

#-----------------------------------------------------------------------------------
# Rotate IAM keys
#-----------------------------------------------------------------------------------

resource "aws_iam_role" "rotate_iam_keys" {
  name               = "rotate-iam-keys-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

#-----------------------------------------------------------------------------------
# Virus scanning - definition upload
#-----------------------------------------------------------------------------------

resource "aws_iam_role" "virus_scan_definition_upload" {
  name               = "virus_scan_definition_upload"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "virus_scan_definition_upload_policy_document" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${module.s3-clamav-definitions-bucket.bucket.arn}/*"]
  }
}

resource "aws_iam_policy" "virus_scan_definition_upload" {
  name        = "virus-scan-definitions-upload-policy"
  description = "Policy for Lambda to get and upload latest clamav virus definitions"
  policy      = data.aws_iam_policy_document.virus_scan_definition_upload_policy_document.json
}

resource "aws_iam_role_policy_attachment" "virus_scan_definition_upload_policy_attachment" {
  role       = aws_iam_role.virus_scan_definition_upload.name
  policy_arn = aws_iam_policy.virus_scan_definition_upload.arn
}

#-----------------------------------------------------------------------------------
# Virus scanning - file scanning
#-----------------------------------------------------------------------------------

resource "aws_iam_role" "virus_scan_file" {
  name               = "virus_scan_file"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "virus_scan_file_policy_document" {
  statement {
    sid    = "S3PermissionsForScanDefinitionsBucket"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${module.s3-clamav-definitions-bucket.bucket.arn}/*"]
  }
  statement {
    sid    = "S3PermissionsForReceivedBucket"
    effect = "Allow"
    actions = [
      "s3:CopyObject",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:GetObjectTagging",
    ]
    resources = ["${module.s3-received-files-bucket.bucket.arn}/*"]
  }
  statement {
    sid    = "S3PermissionsForQuarantineAndProcessedBucket"
    effect = "Allow"
    actions = [
      "s3:CopyObject",
      "s3:PutObject",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
    ]
    resources = [
      "${module.s3-quarantine-files-bucket.bucket.arn}/*",
      "${module.s3-data-bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "virus_scan_file" {
  name        = "virus-scan-file-policy"
  description = "Policy for Lambda to virus scan and move files"
  policy      = data.aws_iam_policy_document.virus_scan_file_policy_document.json
}

resource "aws_iam_role_policy_attachment" "virus_scan_file_policy_attachment" {
  role       = aws_iam_role.virus_scan_file.name
  policy_arn = aws_iam_policy.virus_scan_file.arn
}

#-----------------------------------------------------------------------------------
# Load FMS JSON data
#-----------------------------------------------------------------------------------

resource "aws_iam_role" "format_json_fms_data" {
  name               = "format_json_fms_data"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "format_json_fms_data_policy_document" {
  statement {
    sid    = "S3PermissionsForGetUnformattedJSONFiles"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    resources = ["${module.s3-data-bucket.bucket.arn}/*"]
  }
  statement {
    sid    = "S3PermissionsForPutFormattedJSONFiles"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    resources = [
      "${module.s3-raw-formatted-data-bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "format_json_fms_data" {
  name        = "format-json-fms-data"
  description = "Policy for lambda to format FMS data from data to raw-formatted bucket"
  policy      = data.aws_iam_policy_document.format_json_fms_data_policy_document.json
}

resource "aws_iam_role_policy_attachment" "format_json_fms_data_policy_attachment" {
  role       = aws_iam_role.format_json_fms_data.name
  policy_arn = aws_iam_policy.format_json_fms_data.arn
}

#-----------------------------------------------------------------------------------
# Load MDSS JSON data
#-----------------------------------------------------------------------------------

resource "aws_iam_role" "copy_mdss_data" {
  name               = "copy_mdss_data"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "copy_mdss_data_policy_document" {
  statement {
    sid    = "S3PermissionsForGetJSONLFiles"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    resources = ["${module.s3-data-bucket.bucket.arn}/*"]
  }
  statement {
    sid    = "S3PermissionsForPutJSONLFiles"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
    ]
    resources = [
      "${module.s3-raw-formatted-data-bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "copy_mdss_data" {
  name        = "copy-mdss-data"
  description = "Policy for copying MDSS data from data to raw-formatted bucket"
  policy      = data.aws_iam_policy_document.copy_mdss_data_policy_document.json
}

resource "aws_iam_role_policy_attachment" "copy_mdss_data_policy_attachment" {
  role       = aws_iam_role.copy_mdss_data.name
  policy_arn = aws_iam_policy.copy_mdss_data.arn
}

#-----------------------------------------------------------------------------------
# Calculate Checksum Algorithim
#-----------------------------------------------------------------------------------


resource "aws_iam_role" "calculate_checksum" {
  name               = "calculate-checksum-lambda-iam-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "calculate_checksum" {
  statement {
    sid    = "S3ObjectPermissions"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:GetObjectAttributes",
      "s3:GetObjectVersionAttributes",
    ]
    resources = ["${module.s3-data-bucket.bucket.arn}/*"]
  }
  statement {
    sid    = "S3BucketPermissions"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [module.s3-data-bucket.bucket.arn]
  }
}

resource "aws_iam_role_policy" "calculate_checksum" {
  name   = "calculate_checksum-lambda-iam-policy"
  role   = aws_iam_role.calculate_checksum.id
  policy = data.aws_iam_policy_document.calculate_checksum.json
}

#-----------------------------------------------------------------------------------
# Deploy/destroy zero etl
#-----------------------------------------------------------------------------------

resource "aws_iam_role" "zero_etl_snow" {
  name               = "zero-etl-snow-lambda-iam-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "zero_etl_snow" {
  #checkov:skip=CKV_AWS_111 - glue star
  statement {
    sid    = "AllowIntegrationDeploymentDestruction"
    effect = "Allow"
    actions = [
      "glue:*Integration*",
      "glue:*Integration",
      "glue:CreateIntegration",
      "glue:CreateIntegrationResourceProperty",
      "glue:GetIntegrationResourceProperty",
      "glue:UpdateIntegrationResourceProperty"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid    = "AllowConnectionDeploymentDestruction"
    effect = "Allow"
    actions = [
      "glue:CreateConnection",
      "glue:DeleteConnection",
      "glue:BatchDeleteConnection",
      "glue:GetConnection"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:connection/*",
    ]
  }
  statement {
    sid    = "CreateDatabase"
    effect = "Allow"
    actions = [
      "glue:CreateDatabase",
      "glue:GetDatabase"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
    ]
  }
  statement {
    sid       = "ListAccountAlias"
    effect    = "Allow"
    actions   = ["iam:ListAccountAliases"]
    resources = ["*"]
  }
  #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
  statement {
    sid       = "ListAllSecrets"
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }
  statement {
    sid     = "PassRoleToConn"
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.zero_etl_snow_source.arn,
      aws_iam_role.zero_etl_snow_target.arn,
    ]
  }
  statement {
    sid    = "ListAllBuckets"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "zero_etl_snow" {
  name   = "zero-etl-snow-policy"
  policy = data.aws_iam_policy_document.zero_etl_snow.json
}

resource "aws_iam_role_policy_attachment" "zero_etl_snow" {
  role       = aws_iam_role.zero_etl_snow.name
  policy_arn = aws_iam_policy.zero_etl_snow.arn
}

resource "aws_lakeformation_permissions" "lambda_servicenow_create_db" {
  principal        = aws_iam_role.zero_etl_snow.arn
  permissions      = ["CREATE_DATABASE"]
  catalog_resource = true
}

resource "aws_lakeformation_permissions" "lambda_servicenow_bucket" {
  principal   = aws_iam_role.zero_etl_snow.arn
  permissions = ["DATA_LOCATION_ACCESS"]
  data_location {
    arn = aws_lakeformation_resource.data_bucket.arn
  }
}

resource "aws_lakeformation_permissions" "lambda_servicenow_read_db" {
  principal   = aws_iam_role.zero_etl_snow.arn
  permissions = ["DESCRIBE"]
  database {
    name = "servicenow${local.underscore_env}"
  }
}
