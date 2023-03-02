locals {

  baseline_s3_buckets = {
    s3-bucket = {
      iam_policies = module.baseline_presets.s3_iam_policies
    }
  }
}
