<powershell>
Import-Module ECSTools
[Environment]::SetEnvironmentVariable("ECS_CONTAINER_START_TIMEOUT", "15m", [System.EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE", "true", "Machine")
[Environment]::SetEnvironmentVariable("ECS_ENABLE_TASK_IAM_ROLE", "true", "Machine")

Initialize-ECSAgent –Cluster ${cluster_name} -EnableTaskIAMRole -LoggingDrivers '["json-file","awslogs"]'


Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

</powershell>
