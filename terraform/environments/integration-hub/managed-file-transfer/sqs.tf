module "sqs_unscanned_s3_notifications" {
	source  = "terraform-aws-modules/sqs/aws"
	version = "5.2.1"

	name            = "${local.application_name}-unscanned-s3-notifications"
	use_name_prefix = false

	create_queue_policy = false

	create_dlq = true
	dlq_name   = "${local.application_name}-unscanned-s3-notifications-dlq"

	message_retention_seconds    = 1209600
	visibility_timeout_seconds   = 180
	receive_wait_time_seconds    = 20
	dlq_message_retention_seconds = 1209600

	redrive_policy = {
		maxReceiveCount = 5
	}

	tags = local.tags
}