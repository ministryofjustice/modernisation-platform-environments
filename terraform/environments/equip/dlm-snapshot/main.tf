resource "aws_dlm_lifecycle_policy" "dlm_daily_snapshots" {
  description        = format("DLM lifecycle policy for %s-%s EC2 volume snapshots", var.service, var.environment)
  execution_role_arn = aws_iam_role.dlm_lifecycle_role.arn
  state              = upper(var.state)
  tags = merge(var.tags,
    { Name = format("%s-%s-dlm-policy", var.service, var.environment) }
  )

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = format("%s-%s-schedule", var.service, var.environment)

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


resource "aws_iam_role_policy_attachment" "dlm_lifecycle_policy_attachment" {
  role       = aws_iam_role.dlm_lifecycle_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}
