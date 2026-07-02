module "test_log_group" {
  # main = https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/7e165d5fbd77c835bc2ef509aedf0b503755cf60
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/cloudwatch-log-group?ref=7e165d5fbd77c835bc2ef509aedf0b503755cf60"

  name              = "ccms-feasibility-ccms-ebs-test"
  retention_in_days = 30
}
