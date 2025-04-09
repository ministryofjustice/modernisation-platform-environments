module "fis_az_power_interrupt" {
  source = "./modules/aws-fis"

  role_arn      = "arn:aws:iam::053556912568:role/service-role/AWSFISIAMRole-Preprod"
  log_group_arn = "arn:aws:logs:eu-west-2:053556912568:log-group:AWS-FIS-Logs:*"

  targets = {
    ASG = {
      resource_type  = "aws:ec2:autoscaling-group"
      selection_mode = "ALL"
      resource_tags  = { AzImpairmentPower = "IceAsg" }
    },
    ASG-EC2-Instances = {
      resource_type  = "aws:ec2:instance"
      selection_mode = "ALL"
      resource_tags  = { AzImpairmentPower = "IceAsg" }
      filters = [
        { path = "State.Name", values = ["running"] },
        { path = "Placement.AvailabilityZone", values = ["eu-west-2b"] }
      ]
    },
    EBS-Volumes = {
      resource_type  = "aws:ec2:ebs-volume"
      selection_mode = "COUNT(1)"
      resource_tags  = { AzImpairmentPower = "ApiPauseVolume" }
      filters = [
        { path = "Attachments.DeleteOnTermination", values = ["false"] }
      ]
      parameters = {
        availabilityZoneIdentifier = "eu-west-2b"
      }
    },
    EC2-Instances = {
      resource_type  = "aws:ec2:instance"
      selection_mode = "ALL"
      resource_tags  = { AzImpairmentPower = "StopInstances" }
      filters = [
        { path = "State.Name", values = ["running"] },
        { path = "Placement.AvailabilityZone", values = ["eu-west-2b"] }
      ]
    },
    ElastiCache-Cluster = {
      resource_type  = "aws:elasticache:redis-replicationgroup"
      selection_mode = "ALL"
      resource_tags  = { AzImpairmentPower = "DisruptElasticache" }
      parameters = {
        availabilityZoneIdentifier = "eu-west-2b"
      }
    },
    IAM-role = {
      resource_type  = "aws:iam:role"
      selection_mode = "ALL"
      resource_arns  = ["arn:aws:iam::053556912568:role/AmazonSSMRoleForInstancesQuickSetup"]
    },
    RDS-Cluster = {
      resource_type  = "aws:rds:cluster"
      selection_mode = "ALL"
      resource_tags  = { AzImpairmentPower = "DisruptRds" }
      parameters = {
        writerAvailabilityZoneIdentifiers = "eu-west-2b"
      }
    },
    Subnet = {
      resource_type  = "aws:ec2:subnet"
      selection_mode = "ALL"
      resource_tags  = { AzImpairmentPower = "DisruptSubnet" }
      filters = [
        { path = "AvailabilityZone", values = ["eu-west-2b"] }
      ]
      parameters = {
        availabilityZoneIdentifier = "eu-west-2b"
        vpc                        = "vpc-01ccec9b09079530d"
      }
    }
  }

  actions = {
    Failover-RDS = {
      action_id  = "aws:rds:failover-db-cluster"
      parameters = {}
      targets    = { Clusters = "RDS-Cluster" }
    },
    Pause-ASG-Scaling = {
      action_id  = "aws:ec2:asg-insufficient-instance-capacity-error"
      parameters = {
        availabilityZoneIdentifiers = "euw2-az3"
        duration                    = "PT1H"
        percentage                  = "100"
      }
      targets = { AutoScalingGroups = "ASG" }
    },
    Pause-EBS-IO = {
      action_id  = "aws:ebs:pause-volume-io"
      parameters = { duration = "PT1H" }
      targets    = { Volumes = "EBS-Volumes" }
      start_after = ["Stop-Instances", "Stop-ASG-Instances"]
    },
    Pause-ElastiCache = {
      action_id  = "aws:elasticache:interrupt-cluster-az-power"
      parameters = { duration = "PT1H" }
      targets    = { ReplicationGroups = "ElastiCache-Cluster" }
    },
    Pause-Instance-Launches = {
      action_id  = "aws:ec2:api-insufficient-instance-capacity-error"
      parameters = {
        availabilityZoneIdentifiers = "euw2-az3"
        duration                    = "PT1H"
        percentage                  = "100"
      }
      targets = { Roles = "IAM-role" }
    },
    Pause-network-connectivity = {
      action_id  = "aws:network:disrupt-connectivity"
      parameters = {
        duration = "PT2M"
        scope    = "all"
      }
      targets = { Subnets = "Subnet" }
    },
    Stop-ASG-Instances = {
      action_id  = "aws:ec2:stop-instances"
      parameters = {
        completeIfInstancesTerminated = "true"
        startInstancesAfterDuration   = "PT1H"
      }
      targets = { Instances = "ASG-EC2-Instances" }
    },
    Stop-Instances = {
      action_id  = "aws:ec2:stop-instances"
      parameters = {
        completeIfInstancesTerminated = "true"
        startInstancesAfterDuration   = "PT1H"
      }
      targets = { Instances = "EC2-Instances" }
    }
  }
}
