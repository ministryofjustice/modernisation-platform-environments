#!/bin/bash
    export ip4=$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1)
    # export LOGS="${var.pAppName}-EC2"
    # export APPNAME="${var.pAppName}"
    # export ENV="${var.pEnvironment}"
    # export ROLE="${aws_iam_role.app_ec2_role.name}"
    # export SECRET=`/usr/local/bin/aws --region ${data.aws_region.current.name} secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db_secret.id} --query SecretString --output text`
    # export host="$ip4 $APPNAME-$ENV $APPNAME.${var.pDnsExtension}"
    # /opt/aws/bin/cfn-signal -e 0 --stack ${data.aws_cloudformation_stack.current.name} --resource DBInstance --region ${data.aws_region.current.name}