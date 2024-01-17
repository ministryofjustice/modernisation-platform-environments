accountid            = "738311358426"
vpc_cider_block      = "10.114.224.0/22"
enable_dns_hostnames = "true"
name                 = "cymulatekey" # keypair name 
project_name         = "cymulate"
cymulate_subnets = {
  "cymulate_web_subnet_a_internetfacing" = {
    cidr = "10.114.224.0/24"
    az   = "eu-west-2a"
    env  = "dev"
    name = "cymulate_web_subnet_a_internetfacing"
  },
  "cymulate_web_subnet_private" = {
    cidr = "10.114.225.0/25"
    az   = "eu-west-2b"
    env  = "dev"
    name = "cymulate_web_subnet_private"
  }

}


# Linux Virtual Machine
linux_instance_type               = "t2.micro"
linux_associate_public_ip_address = true
linux_root_volume_size            = 20
linux_root_volume_type            = "gp2"
linux_data_volume_size            = 10
linux_data_volume_type            = "gp2"


# windows Virtual Machine
windows_instance_name               = "cymulate"
windows_instance_type               = "t2.micro"
windows_associate_public_ip_address = true
windows_root_volume_size            = 30
windows_root_volume_type            = "gp2"
windows_data_volume_size            = 10
windows_data_volume_type            = "gp2"

# database parameter
identifier_name = "dev-cymulatemysqlrds"
license_model = "general-public-license"
dbinstance_class = "db.t3.micro"
engine_name ="mysql"
allocated_storage = 5
engine_version ="5.7"
rdsusername = "cymulatepocuser"
rdsport = 3306
db_subnet_group_name = "dev_cymulate_subnet_group"
db_subnets_ciders = {
  dev = ["10.114.227.64/26", "10.114.227.128/26"]
}
allow_db_subnets_ciders = {
  dev = ["10.114.225.0/25", "10.114.225.128/25","10.114.226.0/24", "10.114.227.0/26", "10.114.227.192/26","10.114.224.0/24" ]
}


# EKs cluster parameter 
# eks_subnets_ciders = {
#   dev = ["10.114.226.0/24", "10.114.227.0/26"]
# }

cluster_name = "dev-moj-techdept-cymulate"