locals {
  create_test_harness = local.is-test

  test_harness_iam_name = "${local.application_name}-${local.component_name}-${local.environment}"

  test_writer_function_arn = "arn:aws:lambda:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:function:${local.application_name}-push-to-s3"

  test_harness_trust_policy_documents = data.aws_iam_policy_document.test_harness_trust[*].json
}