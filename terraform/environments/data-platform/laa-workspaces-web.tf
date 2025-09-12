### DATA

data "aws_subnet" "private_aza" {
  filter {
    name   = "tag:Name"
    values = ["platforms-test-general-private-eu-west-2a"]
  }
}

data "aws_subnet" "private_azc" {
  filter {
    name   = "tag:Name"
    values = ["platforms-test-general-private-eu-west-2c"]
  }
}

### SECURITY GROUP

module "workspacesweb_security_group" {

  count = local.environment == "test" ? 1 : 0

  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = "workspacesweb"
  vpc_id = data.aws_vpc.shared.id

  ingress_cidr_blocks = ["10.10.0.0/16"]
  ingress_rules       = ["https-443-tcp"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8090
      protocol    = "tcp"
      description = "User-service ports"
      cidr_blocks = "10.10.0.0/16"
    }
  ]
}

### NETWORK SETTINGS

resource "awscc_workspacesweb_network_settings" "main" {

  count = local.environment == "test" ? 1 : 0

  vpc_id             = data.aws_vpc.shared.id
  subnet_ids         = [data.aws_subnet.private_aza.id, data.aws_subnet.private_azc.id]
  security_group_ids = [module.workspacesweb_security_group[0].security_group_id]
}


### WORKSPACES WEB PORTAL

resource "awscc_workspacesweb_portal" "main" {

  count = local.environment == "test" ? 1 : 0

  display_name         = "laa-workspaces-web"
  network_settings_arn = awscc_workspacesweb_network_settings.main[0].network_settings_arn
}
