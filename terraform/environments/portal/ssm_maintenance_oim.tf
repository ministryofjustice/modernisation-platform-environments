
locals {
  script_oim = <<EOF
#!/bin/bash
. $HOME/.bash_profile
FOL=`date +%d%m%y`
MDOMAIN_HOME=/IDAM/product/runtime/Domain/mserver/domains/IAMGovernanceDomain
cd $DOMAIN_HOME/servers/AdminServer/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim1/$FOL/
  rm $FILE
done
cd $DOMAIN_HOME/servers/AdminServer/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim1/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_oim1/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim1/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_oim1/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim1/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_soa1/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim1/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_soa1/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim1/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_bi1/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim1/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_bi1/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim1/$FOL/
  rm $FILE
done

EOF

  script_oim2 = <<EOF
#!/bin/bash
. $HOME/.bash_profile
FOL=`date +%d%m%y`
MDOMAIN_HOME=/IDAM/product/runtime/Domain/mserver/domains/IAMGovernanceDomain
DOMAIN_HOME=/IDAM/product/runtime/Domain/aserver/domains/IAMGovernanceDomain
cd $DOMAIN_HOME/servers/AdminServer/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim2/$FOL/
  rm $FILE
done
cd $DOMAIN_HOME/servers/AdminServer/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim2/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_oim2/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim2/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_oim2/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim2/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_soa2/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim2/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_soa2/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim2/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_bi2/logs
find . -name "*.log*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim2/$FOL/
  rm $FILE
done
cd $MDOMAIN_HOME/servers/wls_bi2/logs
find . -name "*.out*" -mtime +90 -exec ls -1t {} \; |while read FILE
do
  aws s3 cp $FILE ${local.application_data.accounts[local.environment].url}/oim2/$FOL/
  rm $FILE
done

EOF

}

resource "aws_ssm_maintenance_window" "oim_window" {
  name              = "oim1-${local.application_data.accounts[local.environment].maintenance_window_name}"
  schedule          = "cron(0 0 9 ? * * *)"
  duration          = 4
  cutoff            = 1
  schedule_timezone = "Europe/London"
}

resource "aws_ssm_maintenance_window" "oim2_window" {
  count             = contains(["development", "testing"], local.environment) ? 0 : 1
  name              = "oim2-${local.application_data.accounts[local.environment].maintenance_window_name}"
  schedule          = "cron(0 0 9 ? * * *)"
  duration          = 4
  cutoff            = 1
  schedule_timezone = "Europe/London"
}

resource "aws_ssm_maintenance_window_target" "reg_target_oim" {
  window_id     = aws_ssm_maintenance_window.oim_window.id
  name          = "maintenance-window-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.oim_instance_1.id]
  }
}
resource "aws_ssm_maintenance_window_target" "reg_target_oim2" {
  count         = contains(["development", "testing"], local.environment) ? 0 : 1
  window_id     = aws_ssm_maintenance_window.oim2_window[0].id
  name          = "maintenance-window-target"
  description   = "This is a maintenance window target"
  resource_type = "INSTANCE"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.oim_instance_2[0].id]
  }
}

resource "aws_ssm_maintenance_window_task" "commands_oim" {
  max_concurrency = 2
  max_errors      = 3
  priority        = 1
  task_arn        = "AWS-RunShellScript"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.oim_window.id

  targets {
    key    = "InstanceIds"
    values = [aws_instance.oim_instance_1.id]
  }


  task_invocation_parameters {

    run_command_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "commands"
        values = [local.script_oim]
      }
    }

  }

}

resource "aws_ssm_maintenance_window_task" "commands_oim2" {
  count           = contains(["development", "testing"], local.environment) ? 0 : 1
  max_concurrency = 2
  max_errors      = 3
  priority        = 1
  task_arn        = "AWS-RunShellScript"
  task_type       = "RUN_COMMAND"
  window_id       = aws_ssm_maintenance_window.oim2_window[0].id

  targets {
    key    = "InstanceIds"
    values = [aws_instance.oim_instance_2[0].id]
  }


  task_invocation_parameters {

    run_command_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "commands"
        values = [local.script_oim2]
      }
    }

  }

}