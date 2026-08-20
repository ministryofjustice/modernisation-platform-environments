# resource "aws_cloudwatch_log_group" "eks_auto_mode" {
#   name              = "/aws/eks/${module.eks.cluster_name}/auto-mode"
#   retention_in_days = 30
# }

# resource "aws_cloudwatch_log_delivery_source" "auto_mode_compute" {
#   name         = "${module.eks.cluster_name}-auto-mode-compute"
#   resource_arn = module.eks.cluster_arn
#   log_type     = "AUTO_MODE_COMPUTE_LOGS"
# }

# resource "aws_cloudwatch_log_delivery_source" "auto_mode_block_storage" {
#   name         = "${module.eks.cluster_name}-auto-mode-block-storage"
#   resource_arn = module.eks.cluster_arn
#   log_type     = "AUTO_MODE_BLOCK_STORAGE_LOGS"
# }

# resource "aws_cloudwatch_log_delivery_source" "auto_mode_load_balancing" {
#   name         = "${module.eks.cluster_name}-auto-mode-load-balancing"
#   resource_arn = module.eks.cluster_arn
#   log_type     = "AUTO_MODE_LOAD_BALANCING_LOGS"
# }

# resource "aws_cloudwatch_log_delivery_source" "auto_mode_ipam" {
#   name         = "${module.eks.cluster_name}-auto-mode-ipam"
#   resource_arn = module.eks.cluster_arn
#   log_type     = "AUTO_MODE_IPAM_LOGS"
# }

# resource "aws_cloudwatch_log_delivery_destination" "eks_auto_mode" {
#   name = "${module.eks.cluster_name}-auto-mode"

#   delivery_destination_configuration {
#     destination_resource_arn = aws_cloudwatch_log_group.eks_auto_mode.arn
#   }
# }

# resource "aws_cloudwatch_log_delivery" "auto_mode_compute" {
#   delivery_source_name   = aws_cloudwatch_log_delivery_source.auto_mode_compute.name
#   delivery_destination_arn = aws_cloudwatch_log_delivery_destination.eks_auto_mode.arn
# }

# resource "aws_cloudwatch_log_delivery" "auto_mode_block_storage" {
#   delivery_source_name   = aws_cloudwatch_log_delivery_source.auto_mode_block_storage.name
#   delivery_destination_arn = aws_cloudwatch_log_delivery_destination.eks_auto_mode.arn
# }

# resource "aws_cloudwatch_log_delivery" "auto_mode_load_balancing" {
#   delivery_source_name   = aws_cloudwatch_log_delivery_source.auto_mode_load_balancing.name
#   delivery_destination_arn = aws_cloudwatch_log_delivery_destination.eks_auto_mode.arn
# }

# resource "aws_cloudwatch_log_delivery" "auto_mode_ipam" {
#   delivery_source_name   = aws_cloudwatch_log_delivery_source.auto_mode_ipam.name
#   delivery_destination_arn = aws_cloudwatch_log_delivery_destination.eks_auto_mode.arn
# }