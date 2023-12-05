#------------------------------------------------------------------------------
# Database
#------------------------------------------------------------------------------

resource "aws_db_instance" "database" {
	allocated_storage 					= local.app_data.accounts[local.environment].db_allocated_storage
	storage_type 								= "gp2"
	engine 											= "sqlserver-web"
	engine_version 							= "14.00.3381.3.v1"
	instance_class 							= local.app_data.accounts[local.environment].db_instance_identifier
	identifier									= local.app_data.accounts[local.environment].db_instance_class
	name 												= local.app_data.accounts[local.environment].db_name
	username										= local.app_data.accounts[local.environment].db_user
}

resource "aws_security_group" "db" {
	name 				= "db"
	description = "Allow DB inbound traffic"
	
	ingress {
		from_port 	= 1433
		to_port 		= 1433
		protocol  	= "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

