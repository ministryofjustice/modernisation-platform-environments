#### This file can be used to store locals specific to the member account ####

locals {
  # Bedrock configuration
  bedrock_region = "us-east-1"
  bedrock_models = {
    opus_4_1   = "us.anthropic.claude-opus-4-20250514-v1:0"
    sonnet_4_0 = "us.anthropic.claude-sonnet-4-20250514-v1:0"
  }
}
