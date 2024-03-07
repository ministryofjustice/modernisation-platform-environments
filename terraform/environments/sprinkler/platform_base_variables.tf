variable "networking" {

  type = list(any)

}

variable "collaborator_access" {
  type        = string
  default     = "developer"
  description = "Collaborators must specify which access level they are using, eg set an environment variable of export TF_VAR_collaborator_access=migration"
}

variable "cymulate_agent_linkingkey_1" {
  type        = string
  default     = "df62a2bfcfe74f30e468108eb54a9b1e6cf3a510"
  description = "cymulate linking key"
}

variable "cymulate_agent_linkingkey_2" {
  type        = string
  default     = "11bfa694cce06e4b1518992784bd4ed9916e7bf1"
  description = "cymulate linking key"
}
