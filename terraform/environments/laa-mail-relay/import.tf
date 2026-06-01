# All resources previously targeted by import blocks are now reconciled:
#
# - aws_route53_record.smtp          → already in state (absent from plan)
# - aws_secretsmanager_secret.*      → already in state (absent from plan)
# - aws_iam_user.smtp                → deleted from AWS; Terraform will recreate
# - aws_iam_access_key.smtp          → deleted from AWS; Terraform will recreate
#
# No import blocks are required. This file can be deleted after the next apply.