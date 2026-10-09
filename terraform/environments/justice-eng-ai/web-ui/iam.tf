data "aws_partition" "current" {}

# Shared by every ECS task role/execution role in this component (ui + forge).
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Shared Bedrock invoke policy, attached to both the ui and forge task roles.
data "aws_iam_policy_document" "bedrock_runtime" {
  statement {
    sid    = "InvokeBedrockModels"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    # Cross-region inference profiles (the "eu." prefix on var.bedrock_model_id)
    # can route to foundation models in any eu-* region, so the resource
    # can't be pinned to a single regional model ARN.
    resources = ["*"]
  }
}

resource "aws_iam_policy" "bedrock_runtime" {
  name        = "${local.application_name}-ui-bedrock-runtime"
  description = "Allow ECS tasks to invoke the Bedrock models used by the builder UI and Forge Journey Lab"
  policy      = data.aws_iam_policy_document.bedrock_runtime.json
  tags        = local.tags
}

# ---------- UI task execution role (pulls image, writes logs, reads secrets) ----------

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${local.application_resource_name}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ---------- UI application task role (Bedrock + EFS only, no broad S3) ----------

resource "aws_iam_role" "ecs_task" {
  name               = "${local.application_resource_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_bedrock" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.bedrock_runtime.arn
}

data "aws_iam_policy_document" "ecs_task_efs" {
  statement {
    sid    = "AllowMountAndReadWriteOnPlansAccessPoint"
    effect = "Allow"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]
    resources = [aws_efs_file_system.plans.arn]
    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = [aws_efs_access_point.plans.arn, aws_efs_access_point.data.arn]
    }
  }
}

resource "aws_iam_policy" "ecs_task_efs" {
  name        = "${local.application_resource_name}-ecs-task-efs"
  description = "Allow the builder UI to mount its chat-storage EFS access point"
  policy      = data.aws_iam_policy_document.ecs_task_efs.json
  tags        = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_efs" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.ecs_task_efs.arn
}
