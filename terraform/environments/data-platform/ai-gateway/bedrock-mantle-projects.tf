resource "awscc_bedrockmantle_project" "main" {
  name = local.component_name

  tags = [for k, v in local.tags : { key = k, value = v }]
}
