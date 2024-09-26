module "get_zipped_file_api" {
  source = "./modules/api_step_function"
  api_name = "get_zipped_file"
  api_description = "API to trigger step function that gets a zipped file out of storage"
  api_path = "execute"
  step_function = module.get_zipped_file
  api_key_required = true
  stages = [
    {
      stage_name = "test",
      stage_description = "API Stage for testing",
      burst_limit = 200, 
      rate_limit = 2000, 
      throttling_burst_limit = 200,
      throttling_rate_limit = 2000

    }
  ]
}