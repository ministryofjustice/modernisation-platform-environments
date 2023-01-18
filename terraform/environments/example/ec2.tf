# The security group code is in the original-ec2.tf if is required. It will be needed if there is no default one in place or if you want to add a specific one.
# Copy the code from the above location and give it a suitable name.  

# This code builds a simple EC2 instance and, if needed, increases the size of root volume (commented out at present)

resource "aws_instance" "app_server" {
  #ami           = "ami-084e8c05825742534"    # Amazon linux 64 bit
  ami = "ami-07c2ae35d31367b3e" # Canonical, Ubuntu, 22.04 LTS, amd64
  #ami           = "ami-0e322684a5a0074ce"   # Microsoft Windows Server 2022 Full Locale English
  instance_type = "t3.micro"

# The code to increase the volume size of the root volume is also in original-ec2.tf if that is needed. Add it here if required.

  tags = {
    Name = "example-EC2"
  }
}

# This is needed to add a role which can be used to allow access to the instance created.

resource "aws_iam_role" "this" {
  name                 = "example-EC2-role"
  path                 = "/"
  max_session_duration = "3600"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ec2.amazonaws.com"
          }
          "Action" : "sts:AssumeRole",
          "Condition" : {}
        }
      ]
    }
  )
}
