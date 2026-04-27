# Context

Avature is the supplier of MoJ's core Application Tracking System as of Apr 2026. This module builds the components required to integrate Avature's data lake solution (on their own AWS Account) with the corporate data factory.

## Core Infrastructure
This integration requires:
- S3 bucket for landing the data (as parquet files)
- A Glue catalog with the database
- KMS Key for data encryption
- IAM Role with a trust relationship, that Avature's AWS Account can use to push data/ update Glue in the data factory.


## IAM Policies


### S3 and KMS

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::<bucket_name>/data/*"
            ]
        },
        {
            "Action": [
                "kms:Decrypt",
                "kms:Encrypt",
                "kms:GenerateDataKey",
                "kms:ReEncrypt*"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:kms:<region>:<customer_account>:key/<key_id>"
        }
    ]
}
```


### Glue Data Catalog
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "glue:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:glue:<region>:<customer_account>:database/<db_name>"
            ]
        },
        {
            "Action": [
                "glue:*"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:glue:<region>:<customer_account>:table/<db_name>/*"
            ]
        },
        {
            "Action": [
                "glue:GetDatabase",
                "glue:GetTable",
                "glue:SearchTables",
                "glue:DeleteTable",
                "glue:CreateTable",
                "glue:UpdateTable"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:glue:<region>:<customer_account>:catalog"
        }
    ]
}
```

### Trust Relationship

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::<avature_account>:root"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
```