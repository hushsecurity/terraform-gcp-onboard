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
