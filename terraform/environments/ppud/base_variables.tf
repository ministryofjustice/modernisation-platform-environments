variable "networking" {
  type = list(any)
}

variable "instance_ids_wam_alb" {
  type = map(list(string))
  default = {
    dev = ["aws_instance.s609693lo6vw105.id"]
    uat = ["aws_instance.s618358rgvw201.id"]
    #  prod = ["i-0123456789abcdef", "i-abcdef0123456789"]
  }
}

variable "instance_ids_ppud_internal_alb" {
  type = map(list(string))
  default = {
     uat  = ["aws_instance.s618358rgvw023.id"]
  #  prod = ["i-0123456789abcdef", "i-abcdef0123456789"]
  }
}

/*

variable "instance_ids_ad_name" {
  type = map(list(string))
  default = {
     dev = ["aws_instance.s609693lo6vw109", "aws_instance.s609693lo6vw105", "aws_instance.s609693lo6vw104", "aws_instance.s609693lo6vw100", "aws_instance.s609693lo6vw101", "aws_instance.s609693lo6vw103", "aws_instance.s609693lo6vw106", "aws_instance.s609693lo6vw107", "aws_instance.PPUDWEBSERVER2", "aws_instance.s609693lo6vw102", "aws_instance.s609693lo6vw108", "aws_instance.PPUD-DEV-AWS-AD"]
     uat = ["aws_instance.s618358rgvw201", "aws_instance.S618358RGVW202", "aws_instance.s618358rgsw025", "aws_instance.s618358rgvw024", "aws_instance.s618358rgvw023"]
  #  prod = ["i-0123456789abcdef", "i-abcdef0123456789"]
  }
}

*/

variable "instance_ids_ad_ids" {
  type = map(list(string))
  default = {
     dev = ["aws_instance.s609693lo6vw109[0].id", "aws_instance.s609693lo6vw105[0].id", "aws_instance.s609693lo6vw104[0].id", "aws_instance.s609693lo6vw100[0].id", "aws_instance.s609693lo6vw101[0].id", "aws_instance.s609693lo6vw103[0].id", "aws_instance.s609693lo6vw106[0].id", "aws_instance.s609693lo6vw107[0].id", "aws_instance.PPUDWEBSERVER2[0].id", "aws_instance.s609693lo6vw102[0].id", "aws_instance.s609693lo6vw108[0].id", "aws_instance.PPUD-DEV-AWS-AD[0].id"]
     uat  = ["aws_instance.s618358rgvw201[0].id", "aws_instance.S618358RGVW202[0].id", "aws_instance.s618358rgsw025[0].id", "aws_instance.s618358rgvw024[0].id", "aws_instance.s618358rgvw023[0].id"]
  #  prod = ["i-0123456789abcdef", "i-abcdef0123456789"]
  }
}