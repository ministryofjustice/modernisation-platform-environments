module "get_zipped_file_api_api" {
  source          = "./modules/api_step_function"
  api_name        = "get_zipped_file_api"
  api_description = "API to trigger step function that gets a zipped file out of storage"
  api_path        = "execute"
  step_function   = module.get_zipped_file_api
  stages = [
    {
      stage_name             = "test",
      stage_description      = "API Stage for testing",
      burst_limit            = 200,
      rate_limit             = 2000,
      throttling_burst_limit = 200,
      throttling_rate_limit  = 2000

    }
  ]
  schema = {
    type = "object"
    properties = {
      file_name     = { type = "string" }
      zip_file_name = { type = "string" }
    }
    required = ["file_name", "zip_file_name"]
  }
  api_version = "0.1.1"
}

module "ears_sars_api" {
  count           = local.is-development || local.is-production ? 1 : 0
  source          = "./modules/api_step_function"
  api_name        = "ears_sars_api"
  api_description = "Ears and Sars API"
  api_path        = "execute"
  step_function   = module.ears_sars_step_function[0]
  stages = [
    {
      stage_name             = "request",
      stage_description      = "API Stage for testing",
      burst_limit            = 20,
      rate_limit             = 200,
      throttling_burst_limit = 20,
      throttling_rate_limit  = 200

    }
  ]
  schema = {
    type = "object"
    properties = {
      legacy_subject_id      = { type = "string" }
      legacy_order_id        = { type = "string" }
      priority               = { type = "string" }
      monitoring_requirement = { type = "string" }
      request_types = {
        type  = "array"
        items = { type = "string" }
      }
      information_requested_from = { type = "string" }
      information_requested_to   = { type = "string" }
    }
    required = [
      "legacy_subject_id",
      "legacy_order_id",
      "priority",
      "monitoring_requirement",
      "request_types",
      "information_requested_from",
      "information_requested_to"
    ]
  }
  api_version = "0.1.1"
}
