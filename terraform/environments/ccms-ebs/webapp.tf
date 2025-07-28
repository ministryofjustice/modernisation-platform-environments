resource "awscc_transfer_web_app" "test" {
    provider = awscc.test-webapp
    identity_provider_details = {
        instance_arn = "arn:aws:sso:::instance/ssoins-7535d9af4f41fb26"
        role         = "arn:aws:iam::767123802783:role/ccms-ebs-cashoffice-transfer"
    }
}