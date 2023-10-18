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
  type        = list(string)
  default     = ["snapshotDBFunction","deletesnapshotFunction","connectDBFunction"]
}