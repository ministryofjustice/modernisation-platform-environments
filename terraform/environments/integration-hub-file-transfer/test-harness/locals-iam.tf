locals {
  create_test_harness = local.is-test

  test_harness_iam_name = "${local.application_name}-${local.component_name}-${local.environment}"

  test_harness_trust_policy_documents = data.aws_iam_policy_document.test_harness_trust[*].json
}