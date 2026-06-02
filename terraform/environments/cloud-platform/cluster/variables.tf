variable "created_by" {
  type        = string
  default     = null
  description = "User or system identifier to stamp into the immutable created-by tag (set via TF_VAR_created_by on first apply)."

  validation {
    condition     = var.created_by == null || length(trimspace(var.created_by)) > 0
    error_message = "created_by must not be empty."
  }
}

resource "null_resource" "created_by_tag" {
  triggers = {
    # Persist the initial creator value in state; ignore future tf var changes.
    created_by = coalesce(var.created_by, "__unset__")
  }

  lifecycle {
    ignore_changes = [triggers["created_by"]]
  }
}
