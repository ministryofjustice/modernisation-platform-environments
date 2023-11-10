#------------------------------------------------------------------------------
# IAM for S3 data movement operations to and from the Analytical Platform (AP)
# 
#------------------------------------------------------------------------------


# S3 bucket access policy for AP landing bucket (data pushed from 
# Performance Hub to a bucket in the AP account - hence hard-coded bucket name)
# Legacy account was arn:aws:iam::677012035582:policy/read-ap-ppas
resource "aws_iam_policy" "s3_ap_landing_policy" {
  name   = "${local.application_name}-s3-ap-landing-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "MOJAnalyticalPlatformListBucket",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::hmpps-performance-hub-landing"
        },
        {
            "Sid": "MOJAnalyticalPlatformWriteBucket",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::hmpps-performance-hub-landing/*"
        }
    ]
}
EOF
}

# resource "aws_iam_role" "s3_ap_landing_role" {
#   name               = "${local.application_name}-s3-ap-landing-role"
#   assume_role_policy = data.aws_iam_policy_document.s3-access-policy.json
#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-s3-ap-landing-role"
#     }
#   )
# }

# resource "aws_iam_role_policy_attachment" "s3_ap_landing_attachment" {
#   role       = aws_iam_role.s3_ap_landing_role.name
#   policy_arn = aws_iam_policy.s3_ap_landing_policy.arn
# }

# S3 bucket access policy for Performance Hub landing bucket (data pushed from 
# AP to a bucket in this account)
# Legacy account was arn:aws:iam::677012035582:policy/land-data-access-policy
resource "aws_iam_policy" "s3_hub_Landing_policy" {
  name   = "${local.application_name}-s3-hub-landing-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "HubLandBucketLevel",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "${module.ap_landing_bucket.bucket.arn}"
            ]
        },
        {
            "Sid": "HubLandObjectLevel",
            "Effect": "Allow",
            "Action": [
                "s3:GetObjectAcl",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "${module.ap_landing_bucket.bucket.arn}/*"
            ]
        }
    ]
}
EOF
}

# IAM user for uploads & content bucket
# resource "aws_iam_user" "uploaduser" {
#     name = "uploaduser"
# }