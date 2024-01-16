# nomis-development environment settings
locals {

  # baseline config
  development_config = {

    baseline_acm_certificates = {
      remote_desktop_wildcard_cert = {
        # domain_name limited to 64 chars so use modernisation platform domain for this
        # and put the wildcard in the san
        domain_name = module.environment.domains.public.modernisation_platform
        subject_alternate_names = [
          "*.${module.environment.domains.public.application_environment}",
          "*.development.hmpps-domain.service.justice.gov.uk",
          "hmppgw2.justice.gov.uk",
          "*.hmppgw2.justice.gov.uk",
        ]
        external_validation_records_created = true
        cloudwatch_metric_alarms            = module.baseline_presets.cloudwatch_metric_alarms.acm
        tags = {
          description = "wildcard cert for hmpps domain load balancer"
        }
      }
    }

    baseline_ec2_autoscaling_groups = {

      dev-windows-2022 = {
        # ami has unwanted ephemeral device, don't copy all the ebs_volumess
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name                      = "hmpps_windows_server_2022_release_2023-*"
          availability_zone             = null
          ebs_volumes_copy_all_from_ami = false
          user_data_raw                 = base64encode(file("./templates/windows_server_2022-user-data.yaml"))
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["private-dc"]
        })
        ebs_volumes = {
          "/dev/sda1" = { type = "gp3", size = 100 }
        }
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 2
          max_size         = 2
        })
        autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "Windows Server 2022 for connecting to Azure domain"
          os-type     = "Windows"
          component   = "test"
          server-type = "hmpps-windows_2022"
        }
      }
    }

    baseline_lbs = {
      public = merge(local.rds_lbs.public, {
        instance_target_groups = {
          http1 = merge(local.rds_target_groups.http, {
            attachments = [
            ]
          })
          https1 = merge(local.rds_target_groups.https, {
            attachments = [
            ]
          })
        }
        listeners = {
          http = local.rds_lb_listeners.http
          https = merge(local.rds_lb_listeners.https, {
            rules = {
            }
          })
        }
      })
    }

    baseline_route53_zones = {
      "development.hmpps-domain.service.justice.gov.uk" = {
        lb_alias_records = [
          { name = "rdgateway1", type = "A", lbs_map_key = "public" },
          { name = "rdweb1", type = "A", lbs_map_key = "public" },
        ]
      }
    }
  }
}

data "archive_file" "ad-cleanup-lambda" {
  type        = "zip"
  source_dir = "lambda/ad-clean-up"
  output_path = "ad-cleanup-lambda-payload.zip"
}

module "ad-clean-up-lambda" {
  source                 = "github.com/ministryofjustice/modernisation-platform-terraform-lambda-function" # ref for V3.1
  application_name       = "AdObjectCleanUp"
  description            = "Lambda to remove corresponding computer object from Active Directory upon server termination"
  funtion_name           = "ad-object-clean-up-${local.environment}"
  create_role            = false
  lambda_role            = aws_iam_role.lambda-ad-role.arn
  package_type           = "Zip"
  filename               = data.archive_file.ad-cleanup-lambda.output_path
  source_code_hash       = data.archive_file.ad-cleanup-lambda.output_base64sha256
  handler                = "ad-cleanup.lambda_handler"
  runtime                = "python3.8"

  vpc_subnet_ids         = data.aws_subnets.shared-private
  vpc_security_group_ids = locals.security_groups.azure_domain

  # need to think about this - the trigger will be cloudwatch events from multiple accounts
  allowed_triggers = {

    AllowExecutionFromCloudWatch = {
      action     = "lambda:InvokeFunction"
      principal  = "events.amazonaws.com"
      source_arn = aws_cloudwatch_event_rule.instance-state.arn # this will be a data call
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "ad-clean-up-lambda"
    },
  )
}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda-ad-cleanup" {
  name = "LambdaFunctionADCleanUp"
  tags = local.tags

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda-vpc-attachment" {
  role       = aws_iam_role.lambda-vpc-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# need the IAM policy for cloudwatch event triggers
# need the account trust policy
