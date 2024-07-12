locals {
  smtp_userdata = <<EOF
#!/bin/bash

echo "Installing tools required"
apt-get update
apt-get -y install python-pip
apt-get -y install unzip
pip install ansible
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
pip install https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-latest.tar.gz
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. ~/.nvm/nvm.sh
nvm install node
export ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)

# export LOGS="Postfix-EC2"
# export APPNAME="${local.application_name_short}"
export ENV="${local.application_data.accounts[local.environment].env_short}"
# export ROLE="${local.application_name_short}"
# export host="$ip4 $APPNAME-$ENV ${local.application_name_short}"

echo "Updating hosts"
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
echo "$PRIVATE_IP	${data.aws_route53_zone.external.name}		smtp-${local.application_data.accounts[local.environment].env_short}" >> /etc/hosts
hostname -b 
mkdir -p /root/ansible

echo "Getting secrets from Secrets Manager"
export SESP=`/usr/local/bin/aws --region eu-west-2 secretsmanager get-secret-value --secret-id postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD --query SecretString --output text`
export SESU=`/usr/local/bin/aws --region eu-west-2 secretsmanager get-secret-value --secret-id postfix/app/APP_DATA_MIGRATION_SMTP_USER --query SecretString --output text`
export SESANS=`/usr/local/bin/aws --region eu-west-2 secretsmanager get-secret-value --secret-id postfix/app/SESANS --query SecretString --output text`
mkdir -p /run/cfn-init # Path to store cfn-init scripts

echo "Running Ansible Pull"
ansible-pull -U https://$SESANS@github.com/ministryofjustice/laa-aws-postfix-smtp aws/app/ansible/adhoc.yml -i aws/app/ansible/inventory/$ENV --limit=smtp --extra-vars "smtp_user_name=$SESU smtp_user_pass=$SESP" -d /root/ansible

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
  iam_instance_profile        = aws_iam_instance_profile.cwa.id
#   key_name                    = aws_key_pair.cwa.key_name
  user_data_base64            = base64encode(local.smtp_userdata)
  user_data_replace_on_change = true
  metadata_options {
    http_tokens = "optional"
  }

  tags = merge(
    { "instance-scheduling" = "skip-scheduling" },
    local.tags,
    { "Name" = "${upper(local.application_name_short)} SMTP Server" }
  )
}

#################################
# smtp Security Group Rules
#################################

resource "aws_security_group" "smtp" {
  name        = "${local.application_name}-${local.environment}-smtp-security-group"
  description = "Security Group for SMTP server"
  vpc_id      = data.aws_vpc.shared.id

  tags = merge(
    local.tags,
    { "Name" = "${local.application_name}-${local.environment}-smtp-security-group" }
  )

}

resource "aws_vpc_security_group_egress_rule" "smtp_outbound" {
  security_group_id = aws_security_group.smtp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "smtp_vpc" {
  security_group_id            = aws_security_group.smtp.id
  description                  = "SMTP access"
  cidr_ipv4                    = data.aws_vpc.shared.cidr_block
  from_port                    = 25
  ip_protocol                  = "tcp"
  to_port                      = 25
}


### SMTP Secrets Creation

resource "aws_secretsmanager_secret" "smtp_user" {
  name        = "postfix/app/APP_DATA_MIGRATION_SMTP_USER"
  description = "IAM user access key for SMTP"
}

resource "aws_secretsmanager_secret" "smtp_password" {
  name        = "postfix/app/APP_DATA_MIGRATION_SMTP_PASSWORD"
  description = "IAM user access secret for SMTP"
}

resource "aws_secretsmanager_secret" "smtp_sesans" {
  name        = "postfix/app/SESANS"
  description = "Secret to pull from Ansible code from https://github.com/ministryofjustice/laa-aws-postfix-smtp"
}

resource "aws_secretsmanager_secret" "smtp_sesrsap" {
  name        = "postfix/app/SESRSAP"
  description = ""
}

resource "aws_secretsmanager_secret" "smtp_sesrsa" {
  name        = "postfix/app/SESRSA"
  description = ""
}