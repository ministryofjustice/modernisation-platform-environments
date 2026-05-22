##############################################
### SES Email Identity
###
### Verifies the sender email address for WorkSpaces
### user credential delivery.
###
### After terraform apply, AWS sends a verification
### email to the address. Click the link to activate it.
###
### Note: SES starts in sandbox mode — both sender AND
### recipient must be verified identities until a
### production access request is submitted to AWS Support.
### For initial testing this is fine as both sender and
### test recipient will be the same verified address.
##############################################

resource "aws_ses_email_identity" "user_creation_sender" {
  count = local.environment == "development" ? 1 : 0

  email = local.application_data.accounts[local.environment].ses_sender_email
}

##############################################
### Outputs
##############################################

output "ses_sender_email" {
  value       = local.environment == "development" ? aws_ses_email_identity.user_creation_sender[0].email : null
  description = "SES verified sender email address"
}

output "ses_verification_status" {
  value       = local.environment == "development" ? "Check AWS Console → SES → Verified identities to confirm verification status after applying" : null
  description = "Reminder to verify the email after apply"
}
