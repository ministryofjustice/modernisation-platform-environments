# ######################################
# # ECS IAM EXECUTION ROLE AND POLICY
# ######################################
# resource "aws_iam_role" "maat_api_ecs_taks_execution_role" {
#   name = "${local.application_name}-api-task-execution-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "ecs-tasks.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })

#   tags = {
#     Name = "${local.application_name}-api-task-execution-role"
#   }
# }

# resource "aws_iam_policy" "maat_api_ecs_taks_execution_policy" {
#   name = "${local.application_name}-api-task-execution-policy"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "ecr:BatchCheckLayerAvailability",
#           "ecr:GetDownloadUrlForLayer",
#           "ecr:BatchGetImage"
#         ]
#         Resource = "arn:aws:ecr:${local.env_account_region}:374269020027:repository/${local.application_name}-cd-api-ecr-repo"
#       },
#       {
#         Effect = "Allow"
#         Action = [
#           "ecr:GetAuthorizationToken",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents",
#           "cloudwatch:PutMetricData",
#           "sqs:*"
#         ]
#         Resource = "*"
#       },
#       {
#         Effect = "Allow"
#         Action = "ssm:GetParameters"
#         Resource = [
#           "arn:aws:ssm:${local.env_account_region}:${local.env_account_id}:parameter/maat-cd-api/*",
#           "arn:aws:ssm:${local.env_account_region}:${local.env_account_id}:parameter/APP_MAATDB_DBPASSWORD_MLA1",
#           "arn:aws:ssm:${local.env_account_region}:${local.env_account_id}:parameter/APP_MAATDB_DBPASSWORD_TOGDATA"
#         ]
#       }
#     ]
#   })

#   tags = {
#     Name = "${local.application_name}-api-task-execution-policy"
#   }
# }

# resource "aws_iam_role_policy_attachment" "maat_api_task_execution_role_policy_attachment" {
#   role       = aws_iam_role.maat_api_ecs_taks_execution_role.name
#   policy_arn = aws_iam_policy.maat_api_ecs_taks_execution_policy.arn
# }


# ######################################
# # ECS IAM AUTOSCALING ROLE AND POLICY
# ######################################
# resource "aws_iam_role" "maat_api_ecs_autoscaling_role" {
#   name = "${local.application_name}-api-autoscaling-role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "application-autoscaling.amazonaws.com"
#         }
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })

#   tags = {
#     Name = "${local.application_name}-api-autoscaling-role"
#   }
# }

# resource "aws_iam_policy" "maat_api_service_autoscaling_policy" {
#   name = "${local.application_name}-api-aservice-autoscaling"

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "application-autoscaling:*",
#           "cloudwatch:DescribeAlarms",
#           "cloudwatch:PutMetricAlarm",
#           "ecs:DescribeServices",
#           "ecs:UpdateService"
#         ]
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "service_autoscaling_policy_attachment" {
#   role       = aws_iam_role.maat_api_ecs_autoscaling_role.name
#   policy_arn = aws_iam_policy.maat_api_service_autoscaling_policy.arn
# }
