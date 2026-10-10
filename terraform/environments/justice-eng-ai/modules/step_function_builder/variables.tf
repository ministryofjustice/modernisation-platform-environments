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

variable "ec2" {
  description = "Host settings required for EC2 mode and not allowed in Fargate mode. The supplied execution role must permit instance launch, cleanup and starting the expiry workflow."
  type = object({
    launch_template_id      = string
    launch_template_version = string
    subnet_id               = string
    managed_by              = string
    tags                    = map(string)
    registration_attempts   = optional(number, 30)
    max_lifetime_seconds    = optional(number, 5400)
  })
  default = null

  validation {
    condition = var.ec2 == null ? true : (
      length(trimspace(var.ec2.launch_template_id)) > 0 &&
      length(trimspace(var.ec2.launch_template_version)) > 0 &&
      length(trimspace(var.ec2.subnet_id)) > 0 &&
      length(trimspace(var.ec2.managed_by)) > 0 &&
      var.ec2.registration_attempts > 0 &&
      floor(var.ec2.registration_attempts) == var.ec2.registration_attempts &&
      var.ec2.max_lifetime_seconds >= 600
    )
    error_message = "EC2 requires non-empty launch template, version, subnet and ownership settings, positive integer registration_attempts and max_lifetime_seconds of at least 600."
  }
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention for state machine execution logs."
  type        = number
  default     = 30
}