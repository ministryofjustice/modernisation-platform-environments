locals {
  cloudfront_default_cache_behavior = {
    allowed_methods                            = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods                             = ["HEAD", "GET"]
    forwarded_values_query_string              = true
    forwarded_values_headers                   = ["Authorization", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-SmartTV-Viewer", "CloudFront-Is-Tablet-Viewer", "CloudFront-Viewer-Country", "Host", "User-Agent"]
    forwarded_values_cookies_forward           = "whitelist"
    forwarded_values_cookies_whitelisted_names = ["AWSALB", "JSESSIONID", "ORA_WWV_*"]
    viewer_protocol_policy                     = "redirect-to-https"
  }
}
