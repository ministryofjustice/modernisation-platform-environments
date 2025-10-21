# data "aws_bedrock_inference_profile" "main" {
#   for_each = local.environment_configuration.bedrock_inference_profiles

#   inference_profile_id = each.value
# }

# resource "aws_bedrock_inference_profile" "main" {
#   for_each = local.environment_configuration.bedrock_inference_profiles

#   name = "${local.component_name}-${each.key}"

#   model_source {
#     copy_from = data.aws_bedrock_inference_profile.main[each.key].inference_profile_arn
#   }
# }
