variable "source_file" {
  type        = list(any)
  default     = ["dbsnapshot.js","deletesnapshots.py","dbconnect.js"]                    
}

variable "output_path" {
  type        = list(any)
  default     = ["snapshotDBFunction.zip","deletesnapshotFunction.zip","connectDBFunction.zip"]       
}

variable "filename" {
  type    = list(any)
  default = ["snapshotDBFunction.zip", "deletesnapshotFunction.zip","connectDBFunction.zip"]
}

variable "function_name" {
  type        = list(any)
  default     = ["snapshotDBFunction","deletesnapshotFunction","connectDBFunction"]
}

variable "handler" {
  type        = list(any)
  default     = ["snapshot/dbsnapshot.handler","deletesnapshots.lambda_handler","ssh/dbconnect.handler"]      
}

variable "runtime" {
  type        = list(any)
  default     = [ "nodejs18.x","python3.8","nodejs18.x"]            
}