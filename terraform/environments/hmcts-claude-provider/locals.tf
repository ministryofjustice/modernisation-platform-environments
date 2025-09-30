#### This file can be used to store locals specific to the member account ####

locals {
  # Bedrock configuration
  bedrock_region = "eu-west-1"
  bedrock_models = {
    sonnet_4_5 = "anthropic.claude-sonnet-4-5-20250929-v1:0"
    sonnet_4_0 = "anthropic.claude-sonnet-4-20250514-v1:0"
  }
}
