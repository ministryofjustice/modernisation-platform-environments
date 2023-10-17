variable "filename" {
  type    = list(string)
  default = ["snapshotDBFunction", "deletesnapshotFunction"]
}

variable "source_file" {
  type        = list(string)
  description = "source file for Function"
  default     = ["dbsnapshot.js","deletesnapshots.py"]
}

variable "output_path" {
  type        = list(string)
  description = "source file for Function"
  default     = ["connectDBFunction.zip","DeleteEBSPendingSnapshots.zip"]
}

variable "function_name" {
   type        = list(string)
  description = "Function name"
  default     = ["connectDBFunction.zip","DeleteEBSPendingSnapshots.zip"]
}