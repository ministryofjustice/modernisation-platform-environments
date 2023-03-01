// Not sure if this is needed??
# data "aws_elastic_beanstalk_hosted_zone" "current" {}

data "aws_instance" "tipstaff-ec2-instance-dev" {
  depends_on = [
    aws_elastic_beanstalk_application.tipstaff-elastic-beanstalk-app-dev,
    aws_elastic_beanstalk_environment.tipstaff-elastic-beanstalk-env-dev
  ]
  filter {
    name   = "tag:Name"
    values = [local.application_data.accounts[local.environment].environment_name]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_subnets" "tf-subnets" {
  filter {
    name   = "tag:owner"
    values = ["dts-legacy"]
  }
  filter {
    name   = "tag:availability"
    values = ["public"]
  }
}

provider "aws" {
  alias  = "modernisation-platform-access"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${local.modernisation_platform_account_id}:role/ModernisationPlatformAccess"
  }
}

resource "aws_elastic_beanstalk_application" "tipstaff-elastic-beanstalk-app-dev" {
  provider    = aws.modernisation-platform-access
  name        = local.application_data.accounts[local.environment].application_name
  description = "this is the application elastic bean Tipstaff"
}

resource "aws_elastic_beanstalk_environment" "tipstaff-elastic-beanstalk-env-dev" {
  provider               = aws.modernisation-platform-access
  name                   = local.application_data.accounts[local.environment].environment_name
  application            = aws_elastic_beanstalk_application.tipstaff-elastic-beanstalk-app-dev.name
  solution_stack_name    = "64bit Windows Server 2019 v2.10.6 running IIS 10.0"
  tier                   = "WebServer"
  wait_for_ready_timeout = "60m"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "vpc-09a110bcd6ccc856c"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "subnet-049b91f09a6ff9579,subnet-0ed08d9793ddfd6cc,subnet-06d8877eeca2fcc26"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "	subnet-0575451086b4af5de,subnet-023f52b93d5da85d6,subnet-0367222bc33a31ca5"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "Timeout"
    value     = "600"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = local.application_data.accounts[local.environment].instance_type
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "Availability Zones"
    value     = "Any"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "Cooldown"
    value     = "360"
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "true"
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = "Health"
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MinInstancesInService"
    value     = "0"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSize"
    value     = "30"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "BatchSizeType"
    value     = "Percentage"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "Rolling"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "BreachDuration"
    value     = "5"
  }

  ###=========================== Capacity ========================== ###
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "EnableCapacityRebalancing"
    value     = "false"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = "1"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = "1"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "LowerThreshold"
    value     = "2000000"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "MeasureName"
    value     = "NetworkOut"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Period"
    value     = "5"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Unit"
    value     = "Bytes"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "UpperThreshold"
    value     = "6000000"
  }
  setting {
    namespace = "aws:autoscaling:trigger"
    name      = "Statistic"
    value     = "Average"
  }

  ###=========================== Environment Variables ========================== ###
  //Not sure what the client_ID is??
  # setting {
  #   namespace = "aws:elasticbeanstalk:application:environment"
  #   name      = "ida:ClientId"
  #   value     = var.client_ID
  # }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CurServer"
    value     = "DEVELOPMENT"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_NAME"
    value     = "tftipstaffDB"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_HOSTNAME"
    value     = aws_db_instance.tipstaffdbdev.address
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PASSWORD"
    value     = aws_db_instance.tipstaffdbdev.password
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_PORT"
    value     = "5432"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RDS_USERNAME"
    value     = aws_db_instance.tipstaffdbdev.username
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "supportEmail"
    value     = "dts-legacy-apps-support-team@hmcts.net"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "supportTeam"
    value     = "DTS Legacy Apps Support Team"
  }
  ##=========================== Environment Default Process ========================== ###
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthyThresholdCount"
    value     = "5"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "UnhealthyThresholdCount"
    value     = "3"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = "80"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "MatcherHTTPCode"
    value     = "200-302"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckTimeout"
    value     = "5"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckInterval"
    value     = "15"
  }

  ##=========================== Load Balancer ========================== ###

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }
  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "ListenerEnabled"
    value     = "true"
  }
  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "DefaultProcess"
    value     = "default"
  }
  setting {
    namespace = "aws:elbv2:listener:default"
    name      = "Protocol"
    value     = "HTTP"
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "DefaultProcess"
    value     = "default"
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }
  //Not sure about the certificate??
  #  setting {
  #   namespace = "aws:elbv2:listener:443"
  #   name      = "SSLCertificateArns"
  #   value     = var.certificate
  # }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLPolicy"
    value     = "ELBSecurityPolicy-2016-08"
  }

}