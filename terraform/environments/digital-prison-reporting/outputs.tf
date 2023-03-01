output "s3_kms_arn" {
  description = "Amazon S3 Resource KmS KEY (ARN)"
  value       = aws_kms_key.s3.arn
}

output "kinesis_stream_name" {
  description = "The unique Stream name "
  value       = module.kinesis_stream_ingestor.kinesis_stream_name
}

#output "kinesis_stream_shard_count" {
#  description = "The count of Shards for this Stream"
#  value       = module.kinesis_stream_ingestor.kinesis_stream_shard_count
#}

output "kinesis_stream_arn" {
  description = "The Amazon Resource Name (ARN) specifying the Stream"
  value       = module.kinesis_stream_ingestor.kinesis_stream_arn
}

output "kinesis_stream_iam_policy_read_only_arn" {
  description = "The IAM Policy (ARN) read only of the Stream"
  value       = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_read_only_arn
}

output "kinesis_stream_iam_policy_write_only_arn" {
  description = "The IAM Policy (ARN) write only of the Stream"
  value       = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_write_only_arn
}

#output "kinesis_stream_iam_policy_admin_arn" {
#  description = "The IAM Policy (ARN) admin of the Stream"
#  value       = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
#}

### datamart

output "cluster_arn" {
  description = "The datamart cluster ARN"
  value       = module.datamart.cluster_arn
}

output "cluster_id" {
  description = "The datamart cluster ID"
  value       = module.datamart.cluster_id
}

output "cluster_identifier" {
  description = "The datamart cluster identifier"
  value       = module.datamart.cluster_identifier
}

output "cluster_type" {
  description = "The datamart cluster type"
  value       = module.datamart.cluster_type
}

output "cluster_node_type" {
  description = "The type of nodes in the cluster"
  value       = module.datamart.cluster_node_type
}

output "cluster_database_name" {
  description = "The name of the default database in the Cluster"
  value       = module.datamart.cluster_database_name
}

output "cluster_availability_zone" {
  description = "The availability zone of the Cluster"
  value       = module.datamart.cluster_availability_zone
}

output "cluster_automated_snapshot_retention_period" {
  description = "The backup retention period"
  value       = module.datamart.cluster_automated_snapshot_retention_period
}

output "cluster_preferred_maintenance_window" {
  description = "The backup window"
  value       = module.datamart.cluster_preferred_maintenance_window
}

output "cluster_endpoint" {
  description = "The connection endpoint"
  value       = module.datamart.cluster_endpoint
}

output "cluster_hostname" {
  description = "The hostname of the datamart cluster"
  value       = module.datamart.cluster_hostname
}

output "cluster_encrypted" {
  description = "Whether the data in the cluster is encrypted"
  value       = module.datamart.cluster_encrypted
}

output "cluster_security_groups" {
  description = "The security groups associated with the cluster"
  value       = module.datamart.cluster_security_groups
}

output "cluster_vpc_security_group_ids" {
  description = "The VPC security group ids associated with the cluster"
  value       = module.datamart.cluster_vpc_security_group_ids
}

output "cluster_dns_name" {
  description = "The DNS name of the cluster"
  value       = module.datamart.cluster_dns_name
}

output "cluster_port" {
  description = "The port the cluster responds on"
  value       = module.datamart.cluster_port
}

output "cluster_version" {
  description = "The version of datamart engine software"
  value       = module.datamart.cluster_version
}

output "cluster_parameter_group_name" {
  description = "The name of the parameter group to be associated with this cluster"
  value       = module.datamart.cluster_parameter_group_name
}

output "cluster_subnet_group_name" {
  description = "The name of a cluster subnet group to be associated with this cluster"
  value       = module.datamart.cluster_subnet_group_name
}

output "cluster_public_key" {
  description = "The public key for the cluster"
  value       = module.datamart.cluster_public_key
}

output "cluster_revision_number" {
  description = "The specific revision number of the database in the cluster"
  value       = module.datamart.cluster_revision_number
}

output "cluster_nodes" {
  description = "The nodes in the cluster. Each node is a map of the following attributes: `node_role`, `private_ip_address`, and `public_ip_address`"
  value       = module.datamart.cluster_nodes
}

## EC2 Private key
output "ec2_private_key" {
  description = "Ec2 Private Key"
  value       = module.ec2_kinesis_agent.private_key
  #  sensitive = true 
}

# DMS Subnet ids
output "dms_subnets" {
  description = "DMS Subnet IDs"
  value       = module.dms_nomis_t3.dms_subnet_ids
}

## S3 Bucket Outputs # Disabled DPR-287
#output "s3_bucket_id" {
#  description = "S3 Nomis Oracle Notification Bucket ID"
#  value       = module.s3_nomis_oracle_sqs.bucket_id
#}

#output "s3_bucket_arn" { # Disabled DPR-287
#  description = "S3 Nomis Oracle Notification Bucket ARN"
#  value       = module.s3_nomis_oracle_sqs.bucket_arn
#}