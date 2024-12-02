#### This file can be used to store locals specific to the member account ####
locals {

  database_ec2_name = "${local.application_name} Database Server"

  #Lambda files
  dbsnapshot_source_file     = "dbsnapshot.js"
  deletesnapshot_source_file = "deletesnapshots.py"
  dbconnect_source_file      = "dbconnect.js"

  dbsnapshot_output_path     = "dbsnapshot.zip"
  deletesnapshot_output_path = "deletesnapshots.zip"
  dbconnect_output_path      = "dbconnect.zip"

  #Lambda Function creation
  snapshotDBFunctionname     = "snapshotDBFunction"
  snapshotDBFunctionhandler  = "snapshot/dbsnapshot.handler"
  snapshotDBFunctionruntime  = "nodejs18.x"
  snapshotDBFunctionfilename = "dbsnapshot.zip"

  deletesnapshotFunctionname     = "deletesnapshotFunction"
  deletesnapshotFunctionhandler  = "deletesnapshots.lambda_handler"
  deletesnapshotFunctionruntime  = "python3.8"
  deletesnapshotFunctionfilename = "deletesnapshots.zip"

  connectDBFunctionname     = "connectDBFunction"
  connectDBFunctionhandler  = "ssh/dbconnect.handler"
  connectDBFunctionruntime  = "nodejs18.x"
  connectDBFunctionfilename = "dbconnect.zip"

  #layer config
  s3layerkey          = "nodejs.zip"
  compatible_runtimes = "nodejs18.x"

  application_test_url = "https://apex.laa-development.modernisation-platform.service.justice.gov.uk/apex/"

  ecs_target_capacity = 100

  # ECS local variables for ecs.tf
  ec2_ingress_rules = {
    "cluster_ec2_lb_ingress_3" = {
      description     = "Cluster EC2 ingress rule 3"
      from_port       = 32768
      to_port         = 61000
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = [module.alb.security_group.id]
    }
  }
  ec2_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }

  user_data = base64encode(templatefile("user_data.sh", {
    app_name = local.application_name
  }))

  task_definition = templatefile("task_definition.json", {
    app_name          = local.application_name
    memory_allocation = local.application_data.accounts[local.environment].container_memory_allocation
    ecr_url           = "${local.environment_management.account_ids["core-shared-services-production"]}.dkr.ecr.eu-west-2.amazonaws.com/apex-ecr-repo"
    docker_image_tag  = local.application_data.accounts[local.environment].docker_image_tag
    region            = local.application_data.accounts[local.environment].region
    app_db_url        = "${aws_route53_record.apex-db.fqdn}:1521:APEX"
    app_debug_enabled = local.application_data.accounts[local.environment].app_debug_enabled
    # Note that the following secret is created manually on Parameter Store
    db_secret_arn = "arn:aws:ssm:${local.application_data.accounts[local.environment].region}:${local.env_account_id}:parameter/${local.app_db_password_name}"
  })

  env_account_id       = local.environment_management.account_ids[terraform.workspace]
  app_db_password_name = "APP_APEX_DBPASSWORD_TAD"
  db_hostname          = "db.${local.application_name}"

  backup_schedule_tags       = local.environment == "production" ? { "snapshot-35-day-retention" = "yes" } : null
  database-instance-userdata = <<EOF
#!/bin/bash
cd /tmp
yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl start amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo sed -i '/laa-software-library/d' /etc/fstab
sudo sed -i '/efs.eu-west-2/d' /etc/fstab
echo "${aws_efs_file_system.efs.dns_name}:/ /backups nfs4 rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport" >> /etc/fstab
mount -a

sudo su - oracle -c "sqlplus / as sysdba << EOF
shutdown abort;
startup;
exit;
EOF"

cat <<EOT > /u01/app/oracle/product/12.1/network/admin/listener.ora
USE_SID_AS_SERVICE_LISTENER=ON
DIAG_ADR_ENABLED=on

LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${local.db_hostname}.${data.aws_route53_zone.external.name})(PORT = 1521))
    )
  )
SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (SID_NAME = PLSExtProc)
      (ORACLE_HOME = /u01/app/oracle/product/12.1)
      (PROGRAM = extproc)
    )
    (SID_DESC =
      (ORACLE_HOME =/u01/app/oracle/product/12.1)
      (SID_NAME = APEX)
    )
  )
EOT

cat <<EOT > /u01/app/oracle/product/12.1/network/admin/tnsnames.ora
APEX=
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${local.db_hostname}.${data.aws_route53_zone.external.name})(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = APEX)
    )
  )
EOT

sudo su - oracle -c "lsnrctl start LISTENER"

cd /etc
mkdir cloudwatch_agent
cd cloudwatch_agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/redhat/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm
echo '${data.local_file.cloudwatch_agent.content}' > cloudwatch_agent_config.json
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/etc/cloudwatch_agent/cloudwatch_agent_config.json


mkdir /backups/APEX_RMAN
chmod 777 /backups/APEX_RMAN

EOF

}
