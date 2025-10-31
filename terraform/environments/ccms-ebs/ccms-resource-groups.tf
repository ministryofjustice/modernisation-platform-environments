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

resource "aws_resourcegroups_group" "clamav" {
  name        = "clamav"
  description = "ClamAV instances"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [ "AWS::EC2::Instance" ],
  "TagFilters": [
    {
      "Key": "instance-role",
      "Values": ["clamav"]
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

resource "aws_resourcegroups_group" "ftp" {
  name        = "ftp"
  description = "FTP instances"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [ "AWS::EC2::Instance" ],
  "TagFilters": [
    {
      "Key": "instance-role",
      "Values": ["ftp"]
    }
  ]
}
JSON
  }
}

resource "aws_resourcegroups_group" "mailrelay" {
  name        = "mailrelay"
  description = "MailRelay instances"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [ "AWS::EC2::Instance" ],
  "TagFilters": [
    {
      "Key": "instance-role",
      "Values": ["mailrelay"]
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

output "aws_resourcegroups_group_clamav_arn" {
  description = "aws_resourcegroups_group clamav arn"
  value       = "aws_resourcegroups_group.clamav.arn"
}

output "aws_resourcegroups_group_ebsapps_arn" {
  description = "aws_resourcegroups_group ebsapps arn"
  value       = "aws_resourcegroups_group.ebsapps.arn"
}

output "aws_resourcegroups_group_ebsdb_arn" {
  description = "aws_resourcegroups_group ebsdb arn"
  value       = "aws_resourcegroups_group.ebsdb.arn"
}

output "aws_resourcegroups_group_ftp_arn" {
  description = "aws_resourcegroups_group ftp arn"
  value       = "aws_resourcegroups_group.ftp.arn"
}

output "aws_resourcegroups_group_mailrelay_arn" {
  description = "aws_resourcegroups_group mailrelay arn"
  value       = "aws_resourcegroups_group.mailrelay.arn"
}

output "aws_resourcegroups_group_webgate_arn" {
  description = "aws_resourcegroups_group webgate arn"
  value       = "aws_resourcegroups_group.webgate.arn"
}
