variable "backup_policy_name" {
  type        = string
  description = "backup iam policy name"
  default     = ""
}

variable "role" {
  type        = string
  description = "role"
  default     = ""
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
}

variable "filename" {
  type    = list(string)
  default = ["snapshotDBFunction.zip",
            "deletesnapshotFunction.zip"
            ]
}

variable "source_file" {
  type        = list(string)
  description = "source file for Function"
  default     = ["dbsnapshot.js",
                "deletesnapshots.py"
                ]
}

variable "output_path" {
  type        = list(string)
  description = "source file for Function"
  default     = ["snapshotDBFunction.zip",
                "deletesnapshotFunction.zip"
                ]
}

variable "function_name" {
  type        = list(string)
  description = "Function name"
  default     = ["snapshotDBFunction",
                "deletesnapshotFunction"
                ]
}

variable "handler" {
  type        = list(string)
  description = "Function handler"
  default     = ["snapshot/dbsnapshot.handler",
                "deletesnapshots.lambda_handler"
                ]
}

variable "runtime" {
  type        = list(string)
  description = "Function handler"
  default     = [""
                
                ]
}