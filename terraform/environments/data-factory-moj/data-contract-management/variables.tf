variable "registration_image_uri" {
  description = "Published registration image URI, pinned to its SHA-256 digest. Leave null while provisioning the image repository."
  type        = string
  default     = null

  validation {
    condition = var.registration_image_uri == null ? true : can(
      regex(
        "^[^\\s]+@sha256:[a-f0-9]{64}$",
        var.registration_image_uri
      )
    )
    error_message = "Use an image URI ending in @sha256:<64 lowercase hexadecimal characters>."
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
