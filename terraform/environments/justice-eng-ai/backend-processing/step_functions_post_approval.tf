locals {
  post_approval_state_machine_name = "${local.application_name}-post-approval"

  # Runs once a build request is approved, either automatically by the control
  # plane or later by a reviewer. Input: {s3_folder, s3_file, ...}.
  post_approval_steps = [
    {
      name               = "build_test_deploy_app_image"
      type               = "step_function"
      state_machine_name = local.build_image_state_machine_name
      input_path         = "$"
      result_path        = "$.build_test_deploy_app_image"
    },
    {
      name               = "build_app_infra"
      type               = "step_function"
      state_machine_name = local.build_infra_state_machine_name
      input_path         = "$.build_test_deploy_app_image.Output"
      result_path        = "$.build_app_infra"
    },
  ]
}

module "step_functions_post_approval" {
  source = "../modules/step_function_builder"

  name               = local.post_approval_state_machine_name
  steps              = local.post_approval_steps
  execution_role_arn = aws_iam_role.step_functions_common.arn
  tags               = local.tags

  depends_on = [
    aws_iam_role_policy.step_functions_common,
    module.step_functions_build_image,
    module.step_functions_build_infra,
  ]
}
