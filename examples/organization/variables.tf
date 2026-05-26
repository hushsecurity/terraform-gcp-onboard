variable "hush_org_id" {
  description = "Hush Security organization ID."
  type        = string
}

variable "hush_integration_id" {
  description = "Hush Security integration ID. Optional - generates unique name when omitted."
  type        = string
  default     = null
}

variable "gcp_organization_id" {
  description = "Numeric GCP organization ID."
  type        = string
}

variable "service_account_project_id" {
  description = "GCP project ID where the service account will be created."
  type        = string
}
