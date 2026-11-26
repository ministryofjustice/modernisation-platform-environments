# These three accounts were bootstrapped in development before the stack split.
# Forget only their secrets and keys; operators retain them for recovery and
# delete them separately (docs/grafana-cloud/pdc-token-rotation.md).
moved {
  from = aws_secretsmanager_secret.gc_pdc_token["cloud-platform-preproduction"]
  to   = aws_secretsmanager_secret.cp3_preproduction_handoff
}

removed {
  from = aws_secretsmanager_secret.cp3_preproduction_handoff
  lifecycle {
    destroy = false
  }
}

moved {
  from = aws_kms_key.gc_pdc_token["cloud-platform-preproduction"]
  to   = aws_kms_key.cp3_preproduction_handoff
}

removed {
  from = aws_kms_key.cp3_preproduction_handoff
  lifecycle {
    destroy = false
  }
}

moved {
  from = aws_secretsmanager_secret.gc_pdc_token["cloud-platform-nonlive"]
  to   = aws_secretsmanager_secret.cp3_nonlive_handoff
}

removed {
  from = aws_secretsmanager_secret.cp3_nonlive_handoff
  lifecycle {
    destroy = false
  }
}

moved {
  from = aws_kms_key.gc_pdc_token["cloud-platform-nonlive"]
  to   = aws_kms_key.cp3_nonlive_handoff
}

removed {
  from = aws_kms_key.cp3_nonlive_handoff
  lifecycle {
    destroy = false
  }
}

moved {
  from = aws_secretsmanager_secret.gc_pdc_token["cloud-platform-live"]
  to   = aws_secretsmanager_secret.cp3_live_handoff
}

removed {
  from = aws_secretsmanager_secret.cp3_live_handoff
  lifecycle {
    destroy = false
  }
}

moved {
  from = aws_kms_key.gc_pdc_token["cloud-platform-live"]
  to   = aws_kms_key.cp3_live_handoff
}

removed {
  from = aws_kms_key.cp3_live_handoff
  lifecycle {
    destroy = false
  }
}
