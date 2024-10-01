# In order to add encrypted DMS endpoints we need to add an Oracle SSL Wallet.
# However, this may not exist at the time of running the terraform, so we
# initialize the endpoints with an empty wallet.  We update valid wallets
# using Ansible following creation of the populated wallet.
#
# We use base64 encoding of the originally binary wallet
# (base64 -i cwallet.sso -o empty_wallet_base64.txt)
resource "aws_dms_certificate" "empty_oracle_wallet" {
  certificate_id     = "${var.env_name}-empty-oracle-wallet"
  certificate_wallet = file("files/empty_wallet_base64.txt")
  lifecycle {
    ignore_changes = [certificate_wallet]
  }
}