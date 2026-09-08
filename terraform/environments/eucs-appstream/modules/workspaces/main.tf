###############################################################################
# WorkSpaces service IAM role
###############################################################################

data "aws_iam_policy_document" "workspaces_assume_role" {
  count = var.create_service_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["workspaces.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "workspaces_default" {
  count              = var.create_service_role ? 1 : 0
  name               = "workspaces_DefaultRole"
  assume_role_policy = data.aws_iam_policy_document.workspaces_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "workspaces_service_access" {
  count      = var.create_service_role ? 1 : 0
  role       = aws_iam_role.workspaces_default[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"
}

resource "aws_iam_role_policy_attachment" "workspaces_self_service_access" {
  count      = var.create_service_role ? 1 : 0
  role       = aws_iam_role.workspaces_default[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"
}

#checkov:skip=CKV_AWS_355: DS actions do not support resource-level constraints
#checkov:skip=CKV_AWS_290: DS actions do not support resource-level constraints
resource "aws_iam_role_policy" "workspaces_ds_access" {
  #checkov:skip=CKV_AWS_355: DS actions do not support resource-level constraints
  #checkov:skip=CKV_AWS_290: DS actions do not support resource-level constraints
  count = var.create_service_role ? 1 : 0
  name  = "workspaces-directory-service-access"
  role  = aws_iam_role.workspaces_default[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ds:AuthorizeApplication",
          "ds:UnauthorizeApplication",
          "ds:DescribeDirectories",
          "ds:CheckAlias",
          "ds:CreateAlias",
          "ds:DescribeTrusts",
          "ds:ListAuthorizedApplications"
        ]
        Resource = "*"
      }
    ]
  })
}

###############################################################################
# AD Connector
###############################################################################

resource "aws_directory_service_directory" "ad_connector" {
  name        = var.domain_name
  description = var.ad_connector_description != "" ? var.ad_connector_description : null
  password    = var.ad_connector_password
  size        = var.ad_connector_size
  type        = "ADConnector"

  connect_settings {
    customer_dns_ips  = var.dns_ips
    customer_username = var.ad_connector_username
    subnet_ids        = var.subnet_ids
    vpc_id            = var.vpc_id
  }

  tags = merge(var.tags, {
    "Name" = "${var.application_name}-${var.environment}-ad-connector"
  })

  lifecycle {
    ignore_changes = [password]
  }
}

###############################################################################
# Security group
###############################################################################

#checkov:skip=CKV2_AWS_5: SG is attached via workspace_creation_properties.custom_security_group_id
#checkov:skip=CKV_AWS_382: Egress rules are environment-specific and defined in application_variables.json
resource "aws_security_group" "workspaces" {
  #checkov:skip=CKV2_AWS_5: SG is attached via workspace_creation_properties.custom_security_group_id
  #checkov:skip=CKV_AWS_382: Egress rules are environment-specific and defined in application_variables.json
  name        = var.security_group_name != "" ? var.security_group_name : "${var.application_name}-${var.environment}-workspaces-sg"
  description = var.security_group_description != "" ? var.security_group_description : "Security group for ${var.application_name} WorkSpaces"
  vpc_id      = var.security_group_vpc_id != "" ? var.security_group_vpc_id : var.vpc_id

  dynamic "egress" {
    for_each = var.security_group_egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }

  tags = merge(var.tags, {
    "Name" = var.security_group_name != "" ? var.security_group_name : "${var.application_name}-${var.environment}-workspaces-sg"
  })
}

###############################################################################
# IP access control group
###############################################################################

resource "aws_workspaces_ip_group" "this" {
  name        = var.ip_group_name != "" ? var.ip_group_name : "${var.application_name}-${var.environment}-ip-group"
  description = var.ip_group_description != "" ? var.ip_group_description : "IP access control for ${var.application_name} WorkSpaces"

  dynamic "rules" {
    for_each = var.ip_group_allowed_cidrs
    content {
      source      = rules.value.source
      description = rules.value.description
    }
  }

  tags = merge(var.tags, {
    "Name" = "${var.application_name}-${var.environment}-ip-group"
  })
}

###############################################################################
# WorkSpaces directory registration
###############################################################################

resource "aws_workspaces_directory" "this" {
  directory_id = aws_directory_service_directory.ad_connector.id
  subnet_ids   = var.subnet_ids

  self_service_permissions {
    change_compute_type  = false
    increase_volume_size = false
    rebuild_workspace    = true
    restart_workspace    = true
    switch_running_mode  = false
  }

  workspace_access_properties {
    device_type_android    = "DENY"
    device_type_chromeos   = "DENY"
    device_type_ios        = "DENY"
    device_type_linux      = "DENY"
    device_type_osx        = "DENY"
    device_type_web        = "ALLOW"
    device_type_windows    = "ALLOW"
    device_type_zeroclient = "DENY"
  }

  workspace_creation_properties {
    enable_internet_access              = false
    enable_maintenance_mode             = true
    user_enabled_as_local_administrator = false
    default_ou                          = var.default_ou
  }

  ip_group_ids = [aws_workspaces_ip_group.this.id]

  depends_on = [
    aws_iam_role_policy_attachment.workspaces_service_access,
    aws_iam_role_policy_attachment.workspaces_self_service_access,
    aws_iam_role_policy.workspaces_ds_access,
  ]

  tags = merge(var.tags, {
    "Name" = "${var.application_name}-${var.environment}-workspaces-directory"
  })

  lifecycle {
    ignore_changes = [
      workspace_creation_properties[0].custom_security_group_id,
      workspace_creation_properties[0].default_ou,
      self_service_permissions,
      workspace_access_properties,
    ]
  }
}

###############################################################################
# Individual workspaces — only provisioned when a bundle_id is set
###############################################################################

#checkov:skip=CKV_AWS_156: Existing workspaces were provisioned without encryption; enabling requires rebuild
#checkov:skip=CKV_AWS_155: Existing workspaces were provisioned without encryption; enabling requires rebuild
resource "aws_workspaces_workspace" "this" {
  #checkov:skip=CKV_AWS_156: Existing workspaces were provisioned without encryption; enabling requires rebuild
  #checkov:skip=CKV_AWS_155: Existing workspaces were provisioned without encryption; enabling requires rebuild
  for_each = var.bundle_id != "" ? var.workspace_users : {}

  directory_id = aws_workspaces_directory.this.id
  bundle_id    = var.bundle_id
  user_name    = each.value

  workspace_properties {
    running_mode                              = var.running_mode
    running_mode_auto_stop_timeout_in_minutes = var.running_mode == "AUTO_STOP" ? var.auto_stop_timeout : null
  }

  tags = merge(var.tags, {
    "Name" = "${var.application_name}-${var.environment}-workspace-${each.key}"
    "User" = each.value
  })

  lifecycle {
    ignore_changes = [bundle_id, workspace_properties]
  }
}
