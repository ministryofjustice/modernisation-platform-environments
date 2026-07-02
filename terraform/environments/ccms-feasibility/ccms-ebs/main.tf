module "test_log_group" {
  source = "git::https://github.com/ministryofjustice/laa-ccms-terraform-modules//modules/cloudwatch-log-group?ref=main"

  name              = "ccms-feasibility-ccms-ebs-test"
  retention_in_days = 30
}
