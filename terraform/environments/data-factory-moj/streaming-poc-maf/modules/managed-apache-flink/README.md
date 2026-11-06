# managed-apache-flink

Terraform module for deploying an AWS Managed Service for Apache Flink application, including:

- the Flink application
- IAM roles and policies
- S3 upload of the application JAR
- CloudWatch log group and stream
- optional CloudWatch alarms for application failure and restart loops

