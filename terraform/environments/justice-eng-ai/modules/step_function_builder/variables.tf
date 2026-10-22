variable "name" {
  description = "Name of the Step Functions state machine."
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the shared Step Functions execution role."
  type        = string
}

variable "steps" {
  description = <<-EOT
    Ordered process steps. Each item has a name and type. A script_runner step
    also has script_path, shell_type, and optional variables as {name, value}
    or {name, path}. A script_runner step may set outputs = true so the script
    can return a JSON object (written to SCRIPT_OUTPUT_FILE) at its result_path. A step_function item has state_machine_name and optional
    input_path. Optional retry, timeout_seconds, and result_path fields apply
    to either type.
    A step_function step may set ec2_cleanup = { managed_by = "..." } to
    terminate its disposable hosts when the child fails after task retries.

    A dynamodb_get_item step has table_name, key (attribute name => JSONPath or
    intrinsic for its string value), optional result_attributes (string
    attributes returned at the top level of the result) and optional
    result_path. A dynamodb_query_latest step has table_name, hash_key (JSONPath
    or intrinsic for the string hash key value), result_attributes (attribute
    name => "S" or "N", returned as strings at the top level of the result),
    optional hash_key_name (default AppID), range_key_name (default SysKey) and
    result_path; it reads the newest item with a range key above 0. A
    wait_for_approval step has table_name, app_id and build_id (JSONPaths),
    job_stage, and optional job_status (default awaiting_approval), user_name
    (JSONPath), timeout_seconds (default 31536000) and result_path; it appends
    an event holding the task token and pauses until the token is sent back. A choice step has variable plus equals, or when_absent = true;
    execution continues to the next step when the string matches (or the
    variable is absent) and otherwise ends successfully (optional
    stop_comment). A choice step cannot be last.

    Scope input_path to the specific prior result a step_function step needs
    (e.g. "$.previous_step_name") rather than "$", to avoid forwarding the
    full accumulated state and risking the 256 KB Step Functions data limit.
    See the README for details.
  EOT
  type        = any

  validation {
    condition = alltrue([
      for step in var.steps : try(step.ec2_cleanup, null) == null ? true : (
        step.type == "step_function" && try(length(trimspace(step.ec2_cleanup.managed_by)) > 0, false)
      )
    ])
    error_message = "ec2_cleanup requires a step_function step and a non-empty managed_by tag value."
  }

  validation {
    condition     = length(var.steps) > 0 && length(distinct([for step in var.steps : try(step.name, "")])) == length(var.steps)
    error_message = "Provide at least one step and give every step a unique name."
  }

  validation {
    condition = alltrue([
      for step in var.steps : contains(["script_runner", "step_function", "dynamodb_get_item", "dynamodb_query_latest", "wait_for_approval", "choice"], try(step.type, ""))
    ])
    error_message = "Each step type must be script_runner, step_function, dynamodb_get_item, dynamodb_query_latest, wait_for_approval or choice."
  }

  validation {
    condition = alltrue([
      for step in var.steps : try(step.type, "") == "script_runner" ? (
        try(step.script_path, "") != "" &&
        try(step.shell_type, "") != ""
        ) : try(step.type, "") == "step_function" ? (
        try(step.state_machine_name, "") != "" && !startswith(try(step.state_machine_name, ""), "arn:")
      ) : true
    ])
    error_message = "Script runner steps require script_path and shell_type; step_function steps require a state_machine_name, not an ARN."
  }

  validation {
    condition = alltrue([
      for step in var.steps : try(step.type, "") == "dynamodb_get_item" ? (
        try(step.table_name, "") != "" && try(length(step.key) > 0, false)
      ) : true
    ])
    error_message = "dynamodb_get_item steps require table_name and a non-empty key."
  }

  validation {
    condition = alltrue([
      for step in var.steps : try(step.type, "") == "dynamodb_query_latest" ? (
        try(step.table_name, "") != "" && try(step.hash_key, "") != "" && try(length(step.result_attributes) > 0, false)
      ) : true
    ])
    error_message = "dynamodb_query_latest steps require table_name, hash_key and a non-empty result_attributes map."
  }

  validation {
    condition = alltrue([
      for step in var.steps : try(step.type, "") == "wait_for_approval" ? (
        try(step.table_name, "") != "" && try(step.app_id, "") != "" && try(step.build_id, "") != "" && try(step.job_stage, "") != ""
      ) : true
    ])
    error_message = "wait_for_approval steps require table_name, app_id, build_id and job_stage."
  }

  validation {
    condition = alltrue([
      for step in var.steps : alltrue([
        for name, field in try(step.identity_fields, {}) : try(
          contains(["S", "N"], field.type) && field.path != "" &&
          !contains(["AppID", "SysKey", "BuildID", "TaskToken", "JobStatus", "JobStage", "Date", "UserName"], name), false
        )
      ])
    ])
    error_message = "Approval identity fields require S/N types, a path and non-reserved attribute names."
  }

  validation {
    condition     = length([for step in var.steps : step if try(step.type, "") == "wait_for_approval"]) <= 1
    error_message = "A state machine can have at most one wait_for_approval step."
  }

  validation {
    condition = alltrue([
      for index, step in var.steps : try(step.type, "") == "choice" ? (
        try(step.variable, "") != "" && (try(step.equals, null) != null || try(step.when_absent, false)) && index < length(var.steps) - 1
      ) : true
    ])
    error_message = "choice steps require variable and either equals or when_absent, and cannot be the last step."
  }
}

variable "script_runner" {
  description = "ECS task and network configuration; required when steps include script_runner tasks."
  type = object({
    cluster_arn            = string
    task_definition_family = string
    container_name         = string
    subnets                = list(string)
    security_groups        = list(string)
    assign_public_ip       = string
    execution_role_arn     = string
    task_role_arn          = string
    launch_type            = optional(string, "FARGATE")
  })
  default = null

  validation {
    condition = var.script_runner != null || alltrue([
      for step in var.steps : try(step.type, "") != "script_runner"
    ])
    error_message = "script_runner configuration is required when steps include script_runner tasks."
  }

  validation {
    condition     = var.script_runner == null ? true : contains(["FARGATE", "EC2"], var.script_runner.launch_type)
    error_message = "script_runner.launch_type must be FARGATE or EC2. EC2 always uses a disposable instance."
  }
}

variable "tags" {
  description = "Tags applied to the state machine role and log group."
  type        = map(string)
  default     = {}
}

variable "step_function_retry_attempts" {
  description = "Additional script executions after a non-zero or missing container exit code. Zero disables script retries."
  type        = number
  default     = 3
  nullable    = false

  validation {
    condition     = var.step_function_retry_attempts >= 0 && var.step_function_retry_attempts <= 99999999 && floor(var.step_function_retry_attempts) == var.step_function_retry_attempts
    error_message = "step_function_retry_attempts must be an integer between 0 and 99999999."
  }
}

variable "ec2" {
  description = "Host settings required for EC2 mode and not allowed in Fargate mode. The supplied execution role must permit instance launch and cleanup."
  type = object({
    launch_template_id      = string
    launch_template_version = string
    subnet_id               = string
    managed_by              = string
    tags                    = map(string)
    registration_attempts   = optional(number, 30)
  })
  default = null

  validation {
    condition = var.ec2 == null ? true : (
      length(trimspace(var.ec2.launch_template_id)) > 0 &&
      length(trimspace(var.ec2.launch_template_version)) > 0 &&
      length(trimspace(var.ec2.subnet_id)) > 0 &&
      length(trimspace(var.ec2.managed_by)) > 0 &&
      var.ec2.registration_attempts > 0 &&
      floor(var.ec2.registration_attempts) == var.ec2.registration_attempts
    )
    error_message = "EC2 requires non-empty launch template, version, subnet and ownership settings and positive integer registration_attempts."
  }
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention for state machine execution logs."
  type        = number
  default     = 30
}