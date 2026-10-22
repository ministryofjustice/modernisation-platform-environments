locals {
  submission_environment = [
    { name = "AppID", path = "$.submission.appId" },
    { name = "BuildID", path = "$.submission.buildNumber" },
    { name = "FORGE_BUILD_ID", path = "$.submission.forgeBuildId" },
    { name = "SUBMISSION_ID", path = "$.submission.sysKey" },
    { name = "S3_BUCKET", path = "$.submission.bucket" },
    { name = "S3_KEY", path = "$.submission.key" },
    { name = "SOURCE_SHA256", path = "$.submission.sha256" },
    { name = "SOURCE_ASSURANCE", path = "$.submission.assurance" },
    { name = "SOURCE_VERSION_ID", path = "$.submission.versionId" },
  ]
}
