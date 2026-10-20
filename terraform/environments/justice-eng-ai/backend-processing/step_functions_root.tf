locals {
  root_state_machine_name = "${local.application_name}-root"

  root_process_steps = [
    {
      name               = "control_plane"
      type               = "step_function"
      state_machine_name = local.control_plane_state_machine_name
      input_path         = "$"
      result_path        = "$.control_plane"
    },
    {
      # Requests needing review have a record in the review queue and wait there;
      # approval later starts the post-approval workflow through the EventBridge pipe.
      name         = "approval_gate"
      type         = "choice"
      variable     = "$.control_plane.Output.review.Item"
      when_absent  = true
      stop_comment = "Awaiting review; the post-approval workflow starts when the request is approved."
    },
    {
      name               = "post_approval"
      type               = "step_function"
      state_machine_name = local.post_approval_state_machine_name
      input_path         = "$.control_plane.Output"
      result_path        = "$.post_approval"
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
    module.step_functions_post_approval,
    module.step_functions_control_plane,
  ]
}
