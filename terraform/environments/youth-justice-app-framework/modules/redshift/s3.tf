module "s3" {
  source = "../s3"

  project_name = var.project_name
  environment  = var.environment

  transfer_bucket_name = [local.yjb_bucket_name, local.ycs_bucket_name]

  tags = var.tags

}

locals {
  s3-redshift-yjb-reporting-arn = module.s3.aws_s3_bucket[local.yjb_bucket_name].arn
  s3-redshift-ycs-reporting-arn = module.s3.aws_s3_bucket[local.ycs_bucket_name].arn
}


resource "aws_s3_object" "folder" {
  for_each = toset([local.yjb_s3_folder_moj_ap, local.yjb_s3_folder_landing])

  bucket = local.yjb_bucket_id
  key    = "${each.key}/"
  source = ""
}


resource "aws_s3_bucket_policy" "default" {
  bucket = local.yjb_bucket_id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "DataScientistAccess",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.data_science_role}"
      },
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::${local.yjb_bucket_id}",
        "arn:aws:s3:::${local.yjb_bucket_id}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.data_science_role}"
      },
      "Action": [
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::${local.yjb_bucket_id}/${local.yjb_s3_folder_moj_ap}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${var.data_science_role}"
      },
      "Action": [
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::${local.yjb_bucket_id}/${local.yjb_s3_folder_landing}/*"
      ]
    }
 	]
}
  POLICY

}