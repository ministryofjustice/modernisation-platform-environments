locals {
  root_state_machine_name = "${local.application_name}-root"

  root_process_steps = [
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
      state_machine_name = "${local.application_name}-build-app-infra"
      input_path         = "$.build_test_deploy_app_image"
      result_path        = "$.build_app_infra"
    },
    {
      name               = "deploy_to_infra"
      type               = "step_function"
      state_machine_name = "${local.application_name}-deploy-to-infra"
      input_path         = "$.build_app_infra"
      result_path        = "$.deploy_to_infra"
    },
  ]
}

module "step_functions_root" {
  source = "../modules/step_function_builder"

  name               = local.root_state_machine_name
  steps              = local.root_process_steps
  execution_role_arn = aws_iam_role.step_functions_common.arn
  tags               = local.tags

  depends_on = [
    aws_iam_role_policy.step_functions_common,
    module.step_functions_build_image,
  ]
}
