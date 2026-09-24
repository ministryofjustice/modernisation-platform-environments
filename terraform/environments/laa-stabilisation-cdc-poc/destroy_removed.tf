removed {
  from = module.cwa-poc2-environment.aws_lb.internal

  lifecycle {
    destroy = false
  }
}

removed {
  from = module.cwa-poc2-environment.aws_security_group.internal_lb

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_security_group.backup_lambda

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_lambda_permission.allow_cloudwatch_to_call_check_mon_fri

  lifecycle {
    destroy = false
  }
}

removed {
  from = aws_cloudwatch_event_target.deletesnapshotFunctioncheck_mon_fri

  lifecycle {
    destroy = false
  }
}
