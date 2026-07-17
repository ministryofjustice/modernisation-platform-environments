#--Capacity Providers (Tells the cluster to use the EC2 autoscaling group)
resource "aws_ecs_capacity_provider" "managed" {
  name = "${local.application_data.accounts[local.environment].app_name}-capacity-provider-managed"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.cluster-scaling-group-managed.arn
  }
}

resource "aws_ecs_capacity_provider" "admin" {
  name = "${local.application_data.accounts[local.environment].app_name}-capacity-provider-admin"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.cluster-scaling-group-admin.arn
  }
}

#--Cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.application_data.accounts[local.environment].app_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.managed.name, aws_ecs_capacity_provider.admin.name]
}

#--Admin
resource "aws_ecs_task_definition" "admin" {
  family             = "${local.application_data.accounts[local.environment].app_name}-admin-task"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "EC2",
  ]
  cpu    = local.application_data.accounts[local.environment].admin_container_cpu
  memory = local.application_data.accounts[local.environment].admin_container_memory
  volume {
    name = "soa_volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.storage.id
    }
  }
  volume {
    name      = "inbound_volume"
    host_path = "/home/ec2-user/inbound"
  }

  volume {
    name      = "outbound_volume"
    host_path = "/home/ec2-user/outbound"
  }

  container_definitions = templatefile(
    "${path.module}/templates/task_definition_admin.json.tpl",
    {
      app_name                              = local.application_data.accounts[local.environment].app_name
      app_image                             = local.application_data.accounts[local.environment].admin_app_image
      admin_server_port                     = local.application_data.accounts[local.environment].admin_server_port
      admin_ssl_port                        = local.application_data.accounts[local.environment].admin_ssl_port
      aws_region                            = local.application_data.accounts[local.environment].aws_region
      container_version                     = local.application_data.accounts[local.environment].admin_container_version
      soa_password                          = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/password::"
      db_user                               = local.application_data.accounts[local.environment].soa_db_user
      db_role                               = local.application_data.accounts[local.environment].soa_db_role
      db_instance_endpoint                  = aws_db_instance.soa_db.endpoint
      as_hostname                           = aws_route53_record.admin.fqdn
      wl_admin_mem_args                     = local.application_data.accounts[local.environment].admin_wl_mem_args
      xxsoa_ds_host                         = local.application_data.accounts[local.environment].tds_db_endpoint
      xxsoa_ds_db                           = local.application_data.accounts[local.environment].tds_ds_db
      xxsoa_ds_username                     = local.application_data.accounts[local.environment].admin_xxsoa_ds_username
      xxsoa_ds_url                          = local.application_data.accounts[local.environment].xxsoa_ds_url
      xxsoa_ds_password                     = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/xxsoa/ds/password::"
      ebs_ds_url                            = local.application_data.accounts[local.environment].admin_ebs_ds_url
      ebs_ds_username                       = local.application_data.accounts[local.environment].admin_ebs_ds_username
      ebs_ds_password                       = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/ebs/ds/password::"
      trust_store_password                  = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/java/trust-store/password::"
      ebssms_ds_url                         = local.application_data.accounts[local.environment].admin_ebssms_ds_url
      ebssms_ds_username                    = local.application_data.accounts[local.environment].admin_ebs_ds_username
      ebssms_ds_password                    = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/ebs/sms/ds/password::"
      pui_user_password                     = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/pui/user/password::"
      ebs_user_username                     = local.application_data.accounts[local.environment].admin_ebs_user_username
      ebs_user_password                     = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/ebs/user/password::"
      run_rcu                               = local.application_data.accounts[local.environment].admin_run_rcu_bootstrap
      caab_user                             = local.application_data.accounts[local.environment].admin_caab_user
      pui_user                              = local.application_data.accounts[local.environment].admin_pui_user
      apply_user                            = local.application_data.accounts[local.environment].admin_apply_user
      keystore_secret_id                    = local.application_data.accounts[local.environment].admin_keystore_secret_id
      soa_realm_apply_user_password         = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/apply/password::"
      soa_realm_caab_user_password          = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/caab/password::"
      keystorePassword                      = "${aws_secretsmanager_secret.soa__secrets.arn}:ccms/soa/keystore/password::"
      truststorePassword                    = "${aws_secretsmanager_secret.soa__secrets.arn}:ccms/soa/truststore/password::"
      admin_server_password                 = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/admin/password::"
      edrms_xxsoa_user_password             = "${aws_secretsmanager_secret.soa__secrets.arn}:ccms/soa/xxsoa/password::"
      cwa_apps_user_password                = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/cwa/apps/password::"
      soa_realm_pui_user_password           = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/pui/password::"
      soa_realm_ebs_soa_super_user_password = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/ebs/soa/super/user/password::"
      soa_rds_admin_user_password           = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/password::"
      soa_rds_all_ccmssoa_schema_password   = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/schema/password::"
      extra_java_properties                 = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/extra/java/properties::"

    }
  )
}

resource "aws_ecs_service" "admin" {
  name                               = "${local.application_data.accounts[local.environment].app_name}-admin"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.admin.arn
  desired_count                      = local.application_data.accounts[local.environment].admin_app_count
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  launch_type                        = "EC2"

  health_check_grace_period_seconds = 1800

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:latest == true"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:server == admin"
  }

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks_admin.id]
    subnets         = data.aws_subnets.shared-private.ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.admin_https.id
    container_name   = "${local.application_data.accounts[local.environment].app_name}-admin"
    container_port   = local.application_data.accounts[local.environment].admin_server_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role,
    aws_db_instance.soa_db,
    aws_efs_file_system.storage,
    aws_efs_mount_target.mount,
    aws_efs_mount_target.mount_B,
    aws_efs_mount_target.mount_C
  ]
}

#--Managed
resource "aws_ecs_task_definition" "managed" {
  family             = "${local.application_data.accounts[local.environment].app_name}-managed-task"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  network_mode       = "awsvpc"
  requires_compatibilities = [
    "EC2",
  ]
  cpu    = local.application_data.accounts[local.environment].managed_container_cpu
  memory = local.application_data.accounts[local.environment].managed_container_memory
  volume {
    name = "soa_volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.storage.id
    }
  }
  volume {
    name      = "inbound_volume"
    host_path = "/home/ec2-user/inbound"
  }

  volume {
    name      = "outbound_volume"
    host_path = "/home/ec2-user/outbound"
  }
  container_definitions = templatefile(
    "${path.module}/templates/task_definition_managed.json.tpl",
    {
      app_name             = local.application_data.accounts[local.environment].app_name
      app_image            = local.application_data.accounts[local.environment].managed_app_image
      db_instance_endpoint = aws_db_instance.soa_db.endpoint
      managed_server_port  = local.application_data.accounts[local.environment].managed_server_port
      managed_ssl_port     = local.application_data.accounts[local.environment].managed_ssl_port
      admin_server_port    = local.application_data.accounts[local.environment].admin_server_port
      aws_region           = local.application_data.accounts[local.environment].aws_region
      container_version    = local.application_data.accounts[local.environment].managed_container_version
      admin_host           = aws_route53_record.admin.fqdn
      soa_password         = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/password::"
      trust_store_password = "${aws_secretsmanager_secret.soa_secrets.arn}:ccms/soa/java/trust-store/password::"
      ms_hostname          = aws_route53_record.managed.fqdn
      wl_mem_args          = local.application_data.accounts[local.environment].managed_wl_mem_args
    }
  )
}

resource "aws_ecs_service" "managed" {
  name                               = "${local.application_data.accounts[local.environment].app_name}-managed"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.managed.arn
  desired_count                      = local.application_data.accounts[local.environment].managed_app_count
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 50
  launch_type                        = "EC2"

  health_check_grace_period_seconds = 1800

  ordered_placement_strategy {
    field = "attribute:ecs.availability-zone"
    type  = "spread"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:latest == true"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:server == managed"
  }

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks_managed.id]
    subnets         = data.aws_subnets.shared-private.ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.managed_https.id
    container_name   = "${local.application_data.accounts[local.environment].app_name}-managed"
    container_port   = local.application_data.accounts[local.environment].managed_server_port
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role,
    aws_ecs_service.admin,
  ]
}
