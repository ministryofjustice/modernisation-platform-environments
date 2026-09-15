data "aws_iam_policy_document" "gh_runner_instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_runner_role" {
  name = "${local.component_name}-${local.env_label}-gh-runner-role"

  assume_role_policy = data.aws_iam_policy_document.gh_runner_instance_assume_role_policy.json

  tags = merge(local.tags,
    { Name = "${local.component_name}-${local.env_label}-gh-runner-role" }
  )
}

# Attach AWS managed policy for SSM access
resource "aws_iam_role_policy_attachment" "gh_runner_ssm_managed_policy" {
  role       = aws_iam_role.github_runner_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile for GitHub Runner EC2 Instance
resource "aws_iam_instance_profile" "github_runner_instance_profile" {
  name = "${local.component_name}-${local.env_label}-gh-runner-profile"
  role = aws_iam_role.github_runner_role.name
}
