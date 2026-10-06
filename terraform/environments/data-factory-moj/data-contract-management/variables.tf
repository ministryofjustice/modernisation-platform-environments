variable "registration_image_uris" {
  description = "Registration image URI for each environment, pinned to a SHA-256 digest."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for image_uri in values(var.registration_image_uris) :
      can(regex("^[^\\s]+@sha256:[a-f0-9]{64}$", image_uri))
    ])
    error_message = "Each image URI must end in @sha256:<64 lowercase hexadecimal characters>."
  }
}

variable "registration_architecture" {
  description = "Lambda architecture. The published image must use the same architecture."
  type        = string
  default     = "arm64"

  validation {
    condition = contains(
      ["arm64", "x86_64"],
      var.registration_architecture
    )
    error_message = "Architecture must be arm64 or x86_64."
  }
}

variable "registration_alarm_action_arns" {
  description = "Notification destinations for registration alarms."
  type        = list(string)
  default     = []
}
