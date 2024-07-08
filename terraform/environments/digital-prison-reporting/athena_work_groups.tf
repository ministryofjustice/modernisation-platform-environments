module "athena_workgroup_dpr_generic" {
  source = "./modules/athena_workgroups"

  setup_athena_workgroup = local.setup_dpr_generic_athena_workgroup

  name = format("%s-generic-athena-workgroup", local.project )
  state_enabled = true
  output_location = format("s3://%s/%s", module.s3_working_bucket.bucket_id, local.project)

  tags = merge(
    local.all_tags,
    {
        Resource_Group   = "Athena"
        Resource_Type    = "Athena-Workgroup"
        Jira             = "DPR2-716"
        project          = local.project
        Name             = format("%s-generic-athena-workgroup", local.project )
    }
  )  

}

module "athena_workgroup_analytics_generic" {
  source = "./modules/athena_workgroups"

  setup_athena_workgroup = local.setup_analytics_generic_athena_workgroup

  name = format("%s-generic-athena-workgroup", local.analytics_project_id )  
  state_enabled = true
  output_location = format("s3://%s/%s", module.s3_working_bucket.bucket_id, local.analytics_project_id)

  tags = merge(
    local.all_tags,
    {
        Resource_Group   = "Athena"    
        Resource_Type    = "Athena-Workgroup"
        Jira             = "DPR2-716"
        project          = local.analytics_project_id
        Name             = format("%s-generic-athena-workgroup", local.analytics_project_id )
    }
  )
}