# YJAF EC2 Teraform module

## Summary
This module manages the Tableau instance and Application load balancer and associated security groups. The Items created and modified are:

- Tableau Server ec2 instance.
- Tableau Applicaiton Load Balancer along with its listeners and its target resource of Tableau Server.
- A Security Group for the Tableau Server.
- A Secutity Group for the Load Balancer.
- PostgreSQL and Redshift security group rules to enable access from Tableau Server.
- Directory Service security group rules to enable LDAP & LDAPS access from Tableau Server.

## Inputs:

| Input | Description |
| -------- | ----------- |
| environment | Deployment environment. (Not currently used.) |
| test_mode | (Optional) When test mode is true the destroy command can be used to remove all items. Remove or set to false for production mode. |
| vpc_id | VPC ID as output by the VPC module |
| **Instance Inputs** |
| subnet_id | ID of the Subnet where the instance is to be created. From a VPC module. |
| instance_type | (Optional) Type of EC2 instance to provision. Defalt is t3.nano.
| iam_instance_profile | (Optional) The IAM Role to be assigned to the Tableau instance. Default is TableauSvr.
| instance_volume_size | (Optinal) The size of the volumne to be allocated to the Tableau instance in GB. Defalt 500.
| tableaU_ami_image_id | (Optional) The image ID of the AMI to be used to build the Tableau server instance. It should be set to that of a recent version of CIS Amazon Linux 2 ... Level 1...`. It must have already been approved.
| instance_key_name |The name of the Key Pair to uesd for the Tableau instance. *In future may be created by this module. Alternatively it should be an output from the module that creates it*" |
| private_ip | The IP address to be assigned to the Tablau instance. It is important to retian this value for Tableau licencing. |
| patch_schedule |The required value for the PatchSchedule tag. |
| availability_schedule | The required value for the Schedule tag. |
| **ALB Inputs** |
| alb_name | (Optional) The name of the aplplication Load Balancer that provides access to Tableau server. Default "tableau-alb"
| alb_subnets | List of subnets IDs to which the Tableau applcation load balancer will be assigned. From a VPC module. |
| certificate_arn | The arn of the SSL cetificate to use for external access to Tableau. *May be created by this module in future. Otherwise it should be an output from the module that creates it.*   |
| s3_bucket_for_alb_access_logs | The name of the S3 bucket that is to be used for the Tableau application load balancer. *May be creatd by this module in future. Otherwise is should be an output from the module that creates it.* |
| **Tableau security group inputs** |
| directory_service_sg_id | The ID of the Active directory Service Security Group. Used to add a rules to eneble ldap & ldaps to AD. From a directory Servce module.|
| postgresql_sg_id | The ID of the RDS PostgreSQL Security Group. Used to add a rule to enable Tableau access to PostgreSQL. From a PostgreSQL module.|
| redshift_sg_id | The ID of the Redshift Serverless Security Group. Used to add a rule to enable Tableau access to Redshift. |From a Redshift module.|
| aws_services_sg_id | The ID of the AWS Services Serverless Security Group. Used to add a rule to enable Tableau access to AWS Systems Manager. |
| **Datagog Inputs** |
| datadog-api-key-name | The Name of the Secret that holds the Datagog API Key. |



## Outputs

| Output | Description |
| ------ | ----------- |
|instance_ami | AMI of the Tableau ec2 Instance. |
| instance_arn | ARN for the Tableau ec2 instance. |
| tableau_sg_id | Tableasu security group ID. |
| datedog_secret_arn | ARN for the Secret the holds the Datadog API Key. |

*Other outputs to be added when required by other modules.*

## Import Command examples

### Import Command format:

- `terragrunt import aws_instance.tableau` <*instance ID*>
- `terragrunt import module.tableau_sg.aws_security_group.this` <*Security group ID*>
- `terragrunt import module.postgresql_sg.aws_security_group_rule.ingress_with_source_security_group_id[0]` <*Security Group Rule ID*>

*Note: The rule import did not cause it to be replaced due to confguration preventing changes to the SG. The new rule will simply be added. Not sure what will happen after the new rules have been applied.*

### Sandpit Examples:
- `terragrunt import module.tableau_sg.aws_security_group.this_name_prefix[0] sg-06b19b0386aabd11d`
- `terragrunt import module.tableau_sg.aws_security_group_rule.egress_rules[0] sgr-0fc23d49306fe9f56`
- `terragrunt import module.tableau_sg.aws_security_group_rule.ingress_with_cidr_blocks[0] sg-06b19b0386aabd11d_ingress_tcp_443_443_10.20.10.0/24`
- `terragrunt import module.tableau_sg.aws_security_group_rule.ingress_with_cidr_blocks[1] sg-06b19b0386aabd11d_ingress_tcp_8850_8850_10.20.10.0/24`
- `terragrunt import module.tableau_sg.aws_security_group_rule.ingress_with_source_security_group_id[0] sgr-011c898d7ac4ef764`

- `terragrunt import module.postgresql_sg.module.destination_sg.aws_security_group_rule.ingress_with_source_security_group_id[0] sg-000bced3a1d876af2_ingress_tcp_5432_5432_sg-06b19b0386aabd11d`
- `terragrunt import module.redshift_sg.module.destination_sg aws_security_group_rule.ingress_with_source_security_group_id[0] sg-00add31e86dcf820d_ingress_tcp_5439_5439_sg-06b19b0386aabd11d`


- `terragrunt import module.tableau-alb.aws_lb.this[0] arn:aws:elasticloadbalancing:eu-west-2:856879713508:loadbalancer/app/tableau-alb/04851a42a910ba15`
- `terragrunt import 'module.tableau-alb.aws_lb_listener.this["ex-https"]' arn:aws:elasticloadbalancing:eu-west-2:856879713508:listener/app/tableau-alb/04851a42a910ba15/6361b65e4a41b4bc`
- `terragrunt import 'module.tableau-alb.aws_lb_target_group.this["tableau-instance"]' arn:aws:elasticloadbalancing:eu-west-2:856879713508:targetgroup/tableauhttps/f32fdc5500359183`

- `terragrunt import module.alb_sg.aws_security_group.this_name_prefix[0] sg-04172da8d003ad3e1`
- `terragrunt import module.alb_sg.aws_security_group_rule.egress_with_source_security_group_id[0]sg-04172da8d003ad3e1_egress_tcp_443_443_sg-06b19b0386aabd11d`

- `terragrunt import module.alb_sg.aws_security_group_rule.ingress_rules[0] sg-04172da8d003ad3e1_ingress_tcp_80_80_0.0.0.0/0`
- `terragrunt import module.alb_sg.aws_security_group_rule.ingress_rules[1] sg-04172da8d003ad3e1_ingress_tcp_443_443_0.0.0.0/0`

### Check Status Examples:

- `terragrunt state list`
- `terragrunt state show module.tableau_sg.aws_security_group.this_name_prefix[0]`

### Remove an incorrectly imported item examples:
- `terragrunt state rm module.tableau_sg.aws_security_group.this_name_prefix[0]`
- `terragrunt state rm module.postgresql_sg.module.destination_sg.aws_security_group_rule.ingress_with_source_security_group_id[0]`

