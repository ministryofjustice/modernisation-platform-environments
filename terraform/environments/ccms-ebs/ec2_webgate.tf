/*
resource "aws_instance" "ec2_oracle_ebs" {
  instance_type               = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebs_db
  ami                         = data.aws_ami.oracle_base_prereqs.id
  key_name                    = local.application_data.accounts[local.environment].key_name
  vpc_security_group_ids      = [aws_security_group.ec2_sg_oracle_base.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  monitoring                  = true
  ebs_optimized               = false
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.iam_instace_profile_oracle_base.name
*/
resource "aws_launch_template" "webgate_asg_tpl" {
  name_prefix       = lower(format("ec2-%s-%s-Webgate", local.application_name, local.environment)) 
  image_id          = data.aws_ami.oracle_base_prereqs.id
  instance_type     = local.application_data.accounts[local.environment].ec2_oracle_instance_type_ebs_db
}

resource "aws_autoscaling_group" "webgate_asg" {
  desired_capacity  = 1
  max_size          = 1
  min_size          = 1

  launch_template {
    id      = aws_launch_template.webgate_asg_tpl.id
    version = "$Latest"
  }
}
