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
# DMS Validation Lambda Iam Role
#-----------------------------------------------------------------------------------

data "aws_iam_policy_document" "dms_validation_lambda_role_policy_document" {
  statement {
    sid    = "S3Permissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      "${module.s3-dms-target-store-bucket.bucket.arn}/*",
      module.s3-dms-target-store-bucket.bucket.arn,
    ]
  }
  statement {
    sid    = "DMSPersmissions"
    effect = "Allow"
    actions = [
      "dms:DescribeReplicationTasks",
      "dms:DescribeEndpoints",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "SecretManager"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = ["arn:aws:secretsmanager:eu-west-2:${data.aws_caller_identity.current.account_id}:secret:*"]
  }
}

resource "aws_iam_role" "dms_validation_lambda_role" {
  count              = local.is-production || local.is-development ? 1 : 0
  name               = "dms_validation_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "dms_validation_lambda_role_policy" {
  count  = local.is-production || local.is-development ? 1 : 0
  name   = "dms_validation_lambda_policy"
  policy = data.aws_iam_policy_document.dms_validation_lambda_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "validation_lambda_policy_attachment" {
  count      = local.is-production || local.is-development ? 1 : 0
  role       = aws_iam_role.dms_validation_lambda_role[0].name
  policy_arn = aws_iam_policy.dms_validation_lambda_role_policy[0].arn
}



#-----------------------------------------------------------------------------------
# Process FMS metadata IAM Role
#-----------------------------------------------------------------------------------

data "aws_iam_policy_document" "process_fms_metadata_lambda_role_policy_document" {
  statement {
    sid    = "S3Permissions"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:PutObject",
    ]
    resources = [
      "${module.s3-data-bucket.bucket.arn}/*",
      module.s3-data-bucket.bucket.arn,
    ]
  }
  statement {
    sid    = "SQSQueuePermissions"
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [
      aws_sqs_queue.format_fms_json_event_queue.arn
    ]
  }
}

resource "aws_iam_role" "process_fms_metadata" {
  name               = "process_fms_metadata_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "process_fms_metadata_lambda_role_policy" {
  name   = "process_fms_metadata_lambda_policy"
  policy = data.aws_iam_policy_document.process_fms_metadata_lambda_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "process_fms_metadata_lambda_policy_attachment" {
  role       = aws_iam_role.process_fms_metadata.name
  policy_arn = aws_iam_policy.process_fms_metadata_lambda_role_policy.arn
}



#-----------------------------------------------------------------------------------
# Load DMS Data IAM Role
#-----------------------------------------------------------------------------------

data "aws_iam_policy_document" "load_dms_output_lambda_role_policy_document" {
  statement {
    sid    = "S3Permissions"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAttributes",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${module.s3-create-a-derived-table-bucket.bucket.arn}/staging/*",
      "${module.s3-athena-bucket.bucket.arn}/output/*",
    ]
  }
  statement {
    sid    = "S3GetPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectAttributes",
      "s3:GetObject",
    ]
    resources = [
      "${module.s3-dms-target-store-bucket.bucket.arn}/*"
    ]
  }
  statement {
    sid    = "S3ListingPermissions"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      module.s3-create-a-derived-table-bucket.bucket.arn
    ]
  }
  statement {
    sid    = "AthenaPermissionsForLoadData"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:workgroup/${data.aws_caller_identity.current.id}-default",
    ]
  }
  statement {
    sid    = "GluePermissionsForLoad"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetCatalog"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userDefinedFunction/*/*",
    ]
  }
  statement {
    sid    = "GetDataAccessAndTagsForLakeFormation"
    effect = "Allow"
    actions = [
      "lakeformation:GetDataAccess",
      "lakeformation:GetResourceLFTags",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "ListAccountAlias"
    effect    = "Allow"
    actions   = ["iam:ListAccountAliases"]
    resources = ["*"]
  }
  statement {
    sid       = "ListAllBucket"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "load_dms_output" {
  name               = "load_dms_output_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "load_dms_output_lambda_role_policy" {
  name   = "load_dms_output_lambda_policy"
  policy = data.aws_iam_policy_document.load_dms_output_lambda_role_policy_document.json
}

resource "aws_iam_role_policy_attachment" "load_dms_output_lambda_policy_attachment" {
  role       = aws_iam_role.load_dms_output.name
  policy_arn = aws_iam_policy.load_dms_output_lambda_role_policy.arn
}

module "share_dbs_with_dms_lambda_role" {
  source                  = "./modules/lakeformation_database_share"
  dbs_to_grant            = toset(local.historic_source_dbs)
  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  role_arn                = aws_iam_role.load_dms_output.arn
  db_exists               = true
  de_role_arn             = null
}


#-----------------------------------------------------------------------------------
# Load MDSS Data IAM Role
#-----------------------------------------------------------------------------------

data "aws_iam_policy_document" "load_mdss_lambda_role_policy_document" {
  count = local.is-development ? 0 : 1
  statement {
    sid    = "S3Permissions"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAttributes",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${module.s3-create-a-derived-table-bucket.bucket.arn}/staging/allied_mdss${local.db_suffix}_pipeline/*",
      "${module.s3-athena-bucket.bucket.arn}/output/*",
      "${module.s3-athena-bucket.bucket.arn}/*",
    ]
  }
  statement {
    sid    = "S3GetPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectAttributes",
      "s3:GetObject",
    ]
    resources = [
      "${module.s3-raw-formatted-data-bucket.bucket.arn}/allied/mdss/*"
    ]
  }
  statement {
    sid    = "S3ListingPermissions"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      module.s3-create-a-derived-table-bucket.bucket.arn
    ]
  }
  statement {
    sid    = "AthenaPermissionsForLoadData"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:workgroup/${data.aws_caller_identity.current.id}-default",
    ]
  }
  statement {
    sid    = "GluePermissionsForLoad"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetCatalog"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userDefinedFunction/*/*",
    ]
  }
  statement {
    sid    = "GetDataAccessAndTagsForLakeFormation"
    effect = "Allow"
    actions = [
      "lakeformation:GetDataAccess",
      "lakeformation:GetResourceLFTags",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "ListAccountAlias"
    effect    = "Allow"
    actions   = ["iam:ListAccountAliases"]
    resources = ["*"]
  }
  statement {
    sid       = "ListAllBucket"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "load_mdss" {
  count              = local.is-development ? 0 : 1
  name               = "load_mdss_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "load_mdss_lambda_role_policy" {
  count  = local.is-development ? 0 : 1
  name   = "load_mdss_lambda_policy"
  policy = data.aws_iam_policy_document.load_mdss_lambda_role_policy_document[0].json
}

resource "aws_iam_role_policy_attachment" "load_mdss_output_lambda_policy_attachment" {
  count      = local.is-development ? 0 : 1
  role       = aws_iam_role.load_mdss[0].name
  policy_arn = aws_iam_policy.load_mdss_lambda_role_policy[0].arn
}

module "share_db_with_mdss_lambda_role" {
  count                   = local.is-development ? 0 : 1
  source                  = "./modules/lakeformation_database_share"
  dbs_to_grant            = toset(["allied_mdss${local.db_suffix}"])
  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  role_arn                = aws_iam_role.load_mdss[0].arn
  db_exists               = true
  de_role_arn             = null
}

resource "aws_lakeformation_permissions" "add_create_db" {
  count            = local.is-development ? 0 : 1
  permissions      = ["CREATE_DATABASE", "DROP"]
  principal        = aws_iam_role.load_mdss[0].arn
  catalog_resource = true
}




#-----------------------------------------------------------------------------------
# Load FMS Data IAM Role
#-----------------------------------------------------------------------------------

data "aws_iam_policy_document" "load_fms_lambda_role_policy_document" {
  count = local.is-development ? 0 : 1
  statement {
    sid    = "S3Permissions"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObjectAttributes",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${module.s3-create-a-derived-table-bucket.bucket.arn}/staging/serco_fms${local.db_suffix}_pipeline/*",
      "${module.s3-athena-bucket.bucket.arn}/output/*",
      "${module.s3-athena-bucket.bucket.arn}/*",
    ]
  }
  statement {
    sid    = "S3GetPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectAttributes",
      "s3:GetObject",
    ]
    resources = [
      "${module.s3-raw-formatted-data-bucket.bucket.arn}/serco/fms/*"
    ]
  }
  statement {
    sid    = "S3ListingPermissions"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      module.s3-create-a-derived-table-bucket.bucket.arn
    ]
  }
  statement {
    sid    = "AthenaPermissionsForLoadData"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.id}:workgroup/${data.aws_caller_identity.current.id}-default",
    ]
  }
  statement {
    sid    = "GluePermissionsForLoad"
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetCatalog"
    ]
    resources = [
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:catalog",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:database/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/*/*",
      "arn:aws:glue:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:userDefinedFunction/*/*",
    ]
  }
  statement {
    sid    = "GetDataAccessAndTagsForLakeFormation"
    effect = "Allow"
    actions = [
      "lakeformation:GetDataAccess",
      "lakeformation:GetResourceLFTags",
    ]
    resources = ["*"]
  }
  statement {
    sid       = "ListAccountAlias"
    effect    = "Allow"
    actions   = ["iam:ListAccountAliases"]
    resources = ["*"]
  }
  statement {
    sid       = "ListAllBucket"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets", "s3:GetBucketLocation"]
    resources = ["*"]
  }
}

resource "aws_iam_role" "load_fms" {
  count              = local.is-development ? 0 : 1
  name               = "load_fms_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_policy" "load_fms_lambda_role_policy" {
  count  = local.is-development ? 0 : 1
  name   = "load_fms_lambda_policy"
  policy = data.aws_iam_policy_document.load_fms_lambda_role_policy_document[0].json
}

resource "aws_iam_role_policy_attachment" "load_fms_output_lambda_policy_attachment" {
  count      = local.is-development ? 0 : 1
  role       = aws_iam_role.load_fms[0].name
  policy_arn = aws_iam_policy.load_fms_lambda_role_policy[0].arn
}

module "share_db_with_fms_lambda_role" {
  count                   = local.is-development ? 0 : 1
  source                  = "./modules/lakeformation_database_share"
  dbs_to_grant            = toset(["serco_fms${local.db_suffix}"])
  data_bucket_lf_resource = aws_lakeformation_resource.data_bucket.arn
  role_arn                = aws_iam_role.load_fms[0].arn
  db_exists               = true
  de_role_arn             = null
}

resource "aws_lakeformation_permissions" "add_create_db" {
  count            = local.is-development ? 0 : 1
  permissions      = ["CREATE_DATABASE", "DROP"]
  principal        = aws_iam_role.load_fms[0].arn
  catalog_resource = true
}
