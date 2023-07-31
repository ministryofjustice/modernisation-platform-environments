terraform {
  required_providers {
    aws = {
<<<<<<< HEAD
      version               = "~> 5.0"
      source                = "hashicorp/aws"
      configuration_aliases = [aws.core-vpc] #, aws.core-network-services, aws.us-east-1]
    }
  }
  required_version = ">= 1.1.7"
=======
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.bucket-replication, aws.core-vpc]
    }
  }
  required_version = ">= 1.0.1"
>>>>>>> main
}