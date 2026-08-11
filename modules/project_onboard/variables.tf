variable "project_id" {
  description = "GCP project ID to onboard."
  type        = string
}

variable "iam_member" {
  description = "IAM member string for the Hush service account (e.g., serviceAccount:email)."
  type        = string
}

variable "iam_roles" {
  description = "List of IAM roles to grant in this project."
  type        = list(string)
}

variable "required_apis" {
  description = "List of GCP APIs to enable in this project."
  type        = list(string)
  default     = []
}

variable "enable_vertex_audit_logs" {
  description = "Turn on Data Access audit logs for aiplatform.googleapis.com in this project (required for Vertex agent-activity monitoring; audit-log ingestion is billable)."
  type        = bool
  default     = false
}

variable "create_vertex_billing_exclusion" {
  description = "Add a _Default-sink exclusion dropping the aiplatform Data Access entries Hush does not read. Must be false for projects already collecting aiplatform Data Access logs."
  type        = bool
  default     = false
}

variable "grant_vertex_activity_read" {
  description = "Create a log view scoped to aiplatform Data Access entries and grant the Hush service account read access to that view only."
  type        = bool
  default     = false
}
