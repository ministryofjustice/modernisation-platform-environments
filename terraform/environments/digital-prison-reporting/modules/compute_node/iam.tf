resource "aws_iam_role" "instance-role" {
  count = var.enable_compute_node ? 1 : 0

  name = "${var.name}-role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        },
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "apigateway.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        },        
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "dms.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }        
    ]
}
EOF
}

resource "aws_iam_instance_profile" "profile" {
  count = var.enable_compute_node ? 1 : 0

  name = "${var.name}-profile"
  role = aws_iam_role.instance-role[0].name
}

resource "aws_iam_role_policy_attachment" "ec2-ssm-core" {
  count = var.enable_compute_node ? 1 : 0

  role       = aws_iam_role.instance-role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2-ssm" {
  count = var.enable_compute_node ? 1 : 0

  role       = aws_iam_role.instance-role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.enable_compute_node ? toset(var.policies) : toset([])

  role       = aws_iam_role.instance-role[0].id
  policy_arn = each.value
}
