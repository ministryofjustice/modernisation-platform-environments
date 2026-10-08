# CloudWatch agent for the feasibility EC2 instances, installed and configured through SSM on the running
# instances. Instances are selected by their instance-role tag; each role also needs the agent policy attached
# (module.cloudwatch_agent.agent_policy_arn, or CloudWatchAgentServerPolicy in the sub-stacks).

module "cloudwatch_agent" {
  # https://github.com/ministryofjustice/laa-ccms-terraform-modules/commit/f3bee34
  source = "github.com/ministryofjustice/laa-ccms-terraform-modules//modules/cloudwatch-agent?ref=f3bee34"

  name = local.application_name

  target_tag_values = [
    local.application_data.accounts[local.environment].clamav_instance_role, # clamav-ec2.tf
    "ebsapps",                                                               # ccms-ebs/ebsapps-ec2.tf
    "ebsdb",                                                                 # ccms-ebs/ebsdb-ec2.tf
    "ftp",                                                                   # ccms-ebs/ftp-ec2.tf
  ]

  tags = local.tags
}
