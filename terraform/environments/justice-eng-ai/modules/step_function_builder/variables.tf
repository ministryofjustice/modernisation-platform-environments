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
    or {name, path}. A step_function item has state_machine_name and optional
    input_path. Optional retry, timeout_seconds, and result_path fields apply
    to either type.

    Scope input_path to the specific prior result a step_function step needs
    (e.g. "$.previous_step_name") rather than "$", to avoid forwarding the
    full accumulated state and risking the 256 KB Step Functions data limit.
    See the README for details.
  EOT
  type        = any

  validation {
    condition     = length(var.steps) > 0 && length(distinct([for step in var.steps : try(step.name, "")])) == length(var.steps)
    error_message = "Provide at least one step and give every step a unique name."
  }

  validation {
    condition = alltrue([
      for step in var.steps : contains(["script_runner", "step_function"], try(step.type, ""))
    ])
    error_message = "Each step type must be script_runner or step_function."
  }

  validation {
    condition = alltrue([
      for step in var.steps : try(step.type, "") == "script_runner" ? (
        try(step.script_path, "") != "" &&
        try(step.shell_type, "") != ""
      ) : try(step.state_machine_name, "") != "" && !startswith(try(step.state_machine_name, ""), "arn:")
    ])
    error_message = "Script runner steps require script_path and shell_type; step_function steps require a state_machine_name, not an ARN."
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
  })
  default = null

  validation {
    condition = var.script_runner != null || alltrue([
      for step in var.steps : try(step.type, "") != "script_runner"
    ])
    error_message = "script_runner configuration is required when steps include script_runner tasks."
  }
}

variable "tags" {
  description = "Tags applied to the state machine role and log group."
  type        = map(string)
  default     = {}
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention for state machine execution logs."
  type        = number
  default     = 30
}