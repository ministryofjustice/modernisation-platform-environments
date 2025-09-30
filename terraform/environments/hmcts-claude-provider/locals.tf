#### This file can be used to store locals specific to the member account ####

locals {
  # Bedrock configuration
  bedrock_region = "eu-west-2"
  bedrock_models = {
    sonnet_4_5 = "eu.anthropic.claude-sonnet-4-5-20250929-v1:0"
    sonnet_3_7 = "eu.anthropic.claude-3-7-sonnet-20250219-v1:0"
  }
}
