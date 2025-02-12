#data "short_name" {
#    default = "cica-ap-ingestion"
#}

# create a data variable for the dms_kms module in the file ../kms-keys.tf

data "dms_kms" {
    default = "dms"
}
