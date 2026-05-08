module "lambda_unscanned_to_processing" {
	source  = "terraform-aws-modules/lambda/aws"
	version = "8.8.0"

	function_name = "${local.application_name}-unscanned-to-processing"
	description   = "Moves uploaded files from the unscanned bucket to the processing bucket"
	handler       = "lambda_function.lambda_handler"
	runtime       = "python3.12"
	source_path   = "lambda/file-mover"

	event_source_mapping = {
		sqs = {
			event_source_arn = module.sqs_unscanned_s3_notifications.queue_arn
			batch_size       = 1
		}
	}

	environment_variables = {
		DESTINATION_BUCKET = local.malware_scanning_processing_bucket_name
	}

	attach_policy_statements = true
	policy_statements = {
		source_bucket_read = {
			effect = "Allow"
			actions = [
				"s3:GetObject",
				"s3:GetObjectVersion",
				"s3:GetObjectTagging",
				"s3:GetObjectVersionTagging",
			]
			resources = [
				"${module.s3_bucket["unscanned"].s3_bucket_arn}/*",
			]
		}
		destination_bucket_write = {
			effect = "Allow"
			actions = [
				"s3:PutObject",
				"s3:PutObjectTagging",
				"s3:PutObjectVersionTagging",
			]
			resources = [
				"${module.s3_bucket["processing"].s3_bucket_arn}/*",
			]
		}
	}

	attach_policies    = true
	number_of_policies = 1
	policies = [
		"arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole",
	]

	cloudwatch_logs_retention_in_days = 30

	tags = local.tags
}