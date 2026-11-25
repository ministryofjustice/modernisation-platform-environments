# local-exec uses the apply runner's credentials, not the Terraform AWS provider session.
resource "aws_lambda_permission" "gc_pdc_bootstrap" {
  for_each = {
    for key, config in local.gc_pdc_rotator_deployments : key => config
    if config.bootstrap_enabled && length(local.gc_pdc_bootstrap_accounts) > 0
  }

  statement_id  = "AllowPdcBootstrapFromApply"
  action        = "lambda:InvokeFunction"
  function_name = module.grafana_pdc_token_rotator[each.key].lambda_function_arn
  principal     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-apply"
}

resource "terraform_data" "gc_pdc_bootstrap" {
  for_each = local.gc_pdc_bootstrap_accounts

  # No replacement triggers: image upgrades, schedule enrolment and removal must never issue tokens.
  lifecycle {
    precondition {
      condition     = try(local.environment_configuration_gc.pdc_token_rotator.bootstrap_enabled, false)
      error_message = "A new PDC opt-in requires a reviewed bootstrap-capable rotator release before deploying its agents."
    }
  }

  provisioner "local-exec" {
    command = "python3 \"${path.module}/contrib/bootstrap-pdc-secret.py\""
    environment = {
      PDC_FUNCTION_ARN = module.grafana_pdc_token_rotator["this"].lambda_function_arn
      PDC_SECRET_ARN   = aws_secretsmanager_secret.gc_pdc_token[each.key].arn
    }
  }

  depends_on = [
    aws_secretsmanager_secret_policy.gc_pdc_token,
    aws_lambda_permission.gc_pdc_bootstrap,
    module.grafana_pdc_token_rotator,
  ]
}
