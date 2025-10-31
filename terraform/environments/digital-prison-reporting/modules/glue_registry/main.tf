#---------------------------------------------------
# AWS Glue registry
#---------------------------------------------------
resource "aws_glue_registry" "glue_registry" {
  count = var.enable_glue_registry ? 1 : 0

  registry_name = var.name

  description = var.description

  tags = var.tags


  lifecycle {
    create_before_destroy = true
    ignore_changes        = []
  }

  depends_on = []
}