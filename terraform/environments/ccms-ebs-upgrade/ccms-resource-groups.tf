resource "aws_resourcegroups_group" "accessgate" {
  name        = "accessgate"
  description = "Accessgate instances"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [ "AWS::EC2::Instance" ],
  "TagFilters": [
    {
      "Key": "instance-role",
      "Values": ["accessgate"]
    }
  ]
}
JSON
  }
}

resource "aws_resourcegroups_group" "ebsapps" {
  name        = "ebsapps"
  description = "EBSapps instances"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [ "AWS::EC2::Instance" ],
  "TagFilters": [
    {
      "Key": "instance-role",
      "Values": ["ebsapps"]
    }
  ]
}
JSON
  }
}

resource "aws_resourcegroups_group" "conc" {
  name        = "conc"
  description = "EBSconc instances"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [ "AWS::EC2::Instance" ],
  "TagFilters": [
    {
      "Key": "instance-role",
      "Values": ["conc"]
    }
  ]
}
JSON
  }
}

resource "aws_resourcegroups_group" "ebsdb" {
  name        = "ebsdb"
  description = "EBSdb instances"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [ "AWS::EC2::Instance" ],
  "TagFilters": [
    {
      "Key": "instance-role",
      "Values": ["ebsdb"]
    }
  ]
}
JSON
  }
}

resource "aws_resourcegroups_group" "webgate" {
  name        = "webgate"
  description = "Webgate instances"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [ "AWS::EC2::Instance" ],
  "TagFilters": [
    {
      "Key": "instance-role",
      "Values": ["webgate"]
    }
  ]
}
JSON
  }
}

output "aws_resourcegroups_group_accessgate_arn" {
  description = "aws_resourcegroups_group accessgate arn"
  value       = "aws_resourcegroups_group.accessgate.arn"
}

output "aws_resourcegroups_group_ebsapps_arn" {
  description = "aws_resourcegroups_group ebsapps arn"
  value       = "aws_resourcegroups_group.ebsapps.arn"
}

output "aws_resourcegroups_group_conc_arn" {
  description = "aws_resourcegroups_group conc arn"
  value       = "aws_resourcegroups_group.conc.arn"
}

output "aws_resourcegroups_group_ebsdb_arn" {
  description = "aws_resourcegroups_group ebsdb arn"
  value       = "aws_resourcegroups_group.ebsdb.arn"
}

output "aws_resourcegroups_group_webgate_arn" {
  description = "aws_resourcegroups_group webgate arn"
  value       = "aws_resourcegroups_group.webgate.arn"
}
