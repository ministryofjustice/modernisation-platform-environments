locals {
  root_state_machine_name = "${local.application_name}-root"

  root_process_steps = [
    {
      name               = "resolve_submission"
      type               = "step_function"
      state_machine_name = local.resolve_submission_state_machine_name
      input_path         = "$"
      result_path        = "$.resolved"
    },
    {
      name               = "control_plane"
      type               = "step_function"
      state_machine_name = local.control_plane_state_machine_name
      input_path         = "$.resolved.Output"
      result_path        = "$.control_plane"
    },
    {
      name               = "build_test_deploy_app_image"
      type               = "step_function"
      state_machine_name = local.build_image_state_machine_name
      input_path         = "$.control_plane.Output"
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

module "step_functions_root" {
  source = "../modules/step_function_builder"

  name               = local.root_state_machine_name
  steps              = local.root_process_steps
  execution_role_arn = aws_iam_role.step_functions_common.arn
  tags               = local.tags

  depends_on = [
    aws_iam_role_policy.step_functions_common,
    module.step_functions_build_image,
    module.step_functions_build_infra,
    module.step_functions_control_plane,
    module.step_functions_resolve_submission,
  ]
}
