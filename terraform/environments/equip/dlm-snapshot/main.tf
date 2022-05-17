resource "aws_dlm_lifecycle_policy" "dlm_daily_snapshots" {
  description        = format("DLM lifecycle policy for %s-%s EC2 volume snapshots", var.service, var.environment)
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = upper(var.state)
  tags               = var.tags

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Daily snapshot at 3:00AM"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }

      retain_rule {
        count = 14
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
      }

      copy_tags = true
    }

    target_tags = var.target_tags

  }
}

resource "aws_iam_role" "dlm_lifecycle_role" {
  name               = lower(format("dlm-lifecycle-role-%s-%s", var.service, var.environment))
  assume_role_policy = data.aws_iam_policy_document.dlm_lifecycle_role.json
  tags               = var.tags
}


resource "aws_iam_role_policy_attachment" "dlm_lifecycle_policy" {
  name   = lower(format("dlm-lifecycle-policy-%s-%s", var.service, var.environment))
  role   = aws_iam_role.dlm_lifecycle_role.id
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/AWSDataLifecycleManagerServiceRole"
}
