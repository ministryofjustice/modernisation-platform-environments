# EFS file system for the UI's chat storage (/data/plans inside the container).
#
# Without this, the ECS task volume "plans" is a plain Fargate scratch volume:
# every task restart / deploy / autoscale wipes all chat history, snapshots,
# dispatch log, and the auto-generated .secret_key. EFS gives us:
#
#   * persistence across task restarts and deploys
#   * shared state if / when we scale to >1 task (RWX)
#   * encryption at rest (kms managed by AWS)
#
# Enforced by an EFS access point that fixes uid/gid 1000 (matching the
# non-root ``app`` user in ui/docker/Dockerfile) and roots the mount at
# /plans, so the container never sees anything outside its slice of the fs.

# ---------- file system ----------

resource "aws_efs_file_system" "plans" {
  # checkov:skip=CKV_AWS_184:Encrypted at rest with the AWS-managed EFS KMS
  # key (encrypted = true). A customer-managed CMK adds cost + key rotation
  # ops disproportionate to prototype chat state (no PII / regulated data).

  creation_token = "${local.application_name}-ui-plans"
  encrypted      = true

  # General-purpose perf mode + bursting throughput is right for chat state:
  # low ops / turn, no big-file workloads. Revisit if usage grows.
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  # Transition rarely-accessed files to Infrequent Access after 30 days;
  # bring them back to Standard on any subsequent access. Cost hygiene for
  # dormant chats.
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = merge(local.tags, { Name = "${local.application_name}-ui-plans" })
}

# ---------- security group + mount targets ----------

resource "aws_security_group" "efs_plans" {
  name        = "${local.application_name}-ui-efs"
  description = "Controls access to the UI chat-storage EFS file system"
  vpc_id      = data.terraform_remote_state.justice_eng_ai.outputs.vpc_id
  tags        = merge(local.tags, { Name = "${local.application_name}-ui-efs" })
}

resource "aws_vpc_security_group_ingress_rule" "efs_from_ecs" {
  security_group_id            = aws_security_group.efs_plans.id
  description                  = "NFS from the ECS service"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.ecs_service.id
}

# The ECS SG also needs egress to EFS on 2049. The existing ecs_https rule
# only opens 443, so add a second rule scoped to the EFS SG.
resource "aws_vpc_security_group_egress_rule" "ecs_to_efs" {
  security_group_id            = aws_security_group.ecs_service.id
  description                  = "NFS to the chat-storage EFS"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.efs_plans.id
}

# One mount target per private subnet ECS runs in, so any AZ can attach.
resource "aws_efs_mount_target" "plans" {
  for_each = local.private_subnets_by_key

  file_system_id  = aws_efs_file_system.plans.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_plans.id]
}

# ---------- access point ----------
#
# Pins uid/gid 1000 and roots the mount at /plans so the container writes
# as its non-root user into a bounded subtree. Anything the app does is
# confined to that directory even if it tries paths like ../..

resource "aws_efs_access_point" "plans" {
  file_system_id = aws_efs_file_system.plans.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/plans"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0770"
    }
  }

  tags = merge(local.tags, { Name = "${local.application_name}-ui-plans-ap" })
}

output "efs_plans_file_system_id" {
  description = "ID of the EFS filesystem backing /data/plans in the UI runtime."
  value       = aws_efs_file_system.plans.id
}
