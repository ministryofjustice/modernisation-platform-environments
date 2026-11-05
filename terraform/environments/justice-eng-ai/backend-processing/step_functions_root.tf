locals {
  root_state_machine_name = "${local.application_name}-root"

  root_process_steps = [
    {
      name              = "build_event"
      type              = "dynamodb_query_build"
      table_name        = aws_dynamodb_table.build_review.name
      package_stem      = local.script_runner_package_stem_path
      result_attributes = { BuildID = "N", UserName = "S" }
      result_path       = "$.latest"
    },
    {
      name               = "control_plane"
      type               = "step_function"
      state_machine_name = local.control_plane_state_machine_name
      input_path         = "$"
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
      name               = "prototype_deployment"
      type               = "step_function"
      state_machine_name = local.prototype_deployment_state_machine_name
      input_path         = "$.build_test_deploy_app_image.Output"
      result_path        = "$.deploy_prototype_app"
    },
    {
      # Runs only if build_app_infra succeeded; a failed child fails the root.
      name               = "notify_user"
      type               = "step_function"
      state_machine_name = local.notify_state_machine_name
      input_path         = "$.deploy_prototype_app.Output"
      result_path        = "$.notify_user"
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
    module.step_functions_deploy_prototype,
    module.step_functions_control_plane,
    module.step_functions_notify,
    aws_iam_role_policy.step_functions_common,
  ]
}
