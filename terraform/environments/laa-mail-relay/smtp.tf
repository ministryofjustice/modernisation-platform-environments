locals {
  smtp_userdata = <<EOF
#!/bin/bash

echo "Installing tools required"
apt-get update
apt-get -y install python-pip
apt-get -y install unzip
pip install --upgrade pip
pip install ansible
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
# pip install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz

echo "Installing node using nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. /.nvm/nvm.sh
nvm install node

export ENV="${local.application_data.accounts[local.environment].env_short}"


echo "Updating hosts"
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
echo "$PRIVATE_IP	${data.aws_route53_zone.external.name}		smtp-${local.application_data.accounts[local.environment].env_short}" >> /etc/hosts
hostname -b 
mkdir -p /root/ansible

echo "Getting secrets from Secrets Manager"
export SESP=`/usr/local/bin/aws --region eu-west-2 secretsmanager get-secret-value --secret-id postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD --query SecretString --output text`
export SESU=`/usr/local/bin/aws --region eu-west-2 secretsmanager get-secret-value --secret-id postfix/app/APP_DATA_MIGRATION_SMTP_USER --query SecretString --output text`
export SESANS=`/usr/local/bin/aws --region eu-west-2 secretsmanager get-secret-value --secret-id postfix/app/SESANS_MP --query SecretString --output text`
# mkdir -p /run/cfn-init # Path to store cfn-init scripts

echo "Running Ansible Pull"
ansible-pull -U https://$SESANS@github.com/ministryofjustice/laa-aws-postfix-smtp aws/app/ansible/adhoc.yml -C modernisation-platform -i aws/app/ansible/inventory/$ENV --limit=smtp --extra-vars "smtp_user_name=$SESU smtp_user_pass=$SESP" -d /root/ansible | tail -n +3

EOF
}

######################################
# SMTP Instance
######################################

resource "aws_instance" "smtp" {
  ami                         = local.application_data.accounts[local.environment].smtp_ami_id
  availability_zone           = "eu-west-2a"
  instance_type               = local.application_data.accounts[local.environment].smtp_instance_type
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.smtp.id]
  subnet_id                   = data.aws_subnet.data_subnets_a.id
  iam_instance_profile        = aws_iam_instance_profile.smtp.id
  user_data_base64            = base64encode(local.smtp_userdata)
  user_data_replace_on_change = true
  metadata_options {
    http_tokens = "optional"
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}" }
  )

  depends_on = [
    aws_secretsmanager_secret_version.smtp_user, aws_secretsmanager_secret_version.smtp_password
  ]
}

#################################
# smtp Security Group Rules
#################################

resource "aws_security_group" "smtp" {
  name        = "${local.application_name}-${local.environment}-security-group"
  description = "Security Group for SMTP server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-security-group" }
  )

}

resource "aws_vpc_security_group_egress_rule" "smtp_outbound" {
  security_group_id = aws_security_group.smtp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "smtp_vpc" {
  security_group_id = aws_security_group.smtp.id
  description       = "SMTP access"
  cidr_ipv4         = data.aws_vpc.shared.cidr_block
  from_port         = 25
  ip_protocol       = "tcp"
  to_port           = 25
}

# Domain A record for SMTP server
resource "aws_route53_record" "smtp" {
  provider = aws.core-vpc
  zone_id  = data.aws_route53_zone.external.zone_id
  name     = "laa-mail.${data.aws_route53_zone.external.name}"
  type     = "A"
  ttl      = "60"
  records  = [aws_instance.smtp.private_ip]
}