variable "hush_org_id" {
  description = "Your Hush Security organization ID."
  type        = string

  validation {
    condition     = can(regex("^org-[a-zA-Z0-9]+$", var.hush_org_id)) && length(var.hush_org_id) >= 8 && length(var.hush_org_id) <= 30
    error_message = "hush_org_id must be a valid Hush organization ID (e.g., org-us1234567890abc)."
  }
}

variable "hush_integration_id" {
  description = "Your Hush Security integration ID. When null, a unique service account name is generated automatically."
  type        = string
  default     = null

  validation {
    condition     = var.hush_integration_id == null || (can(regex("^int-[a-zA-Z0-9]+$", var.hush_integration_id)) && length(var.hush_integration_id) >= 8 && length(var.hush_integration_id) <= 30)
    error_message = "hush_integration_id must be a valid Hush integration ID (e.g., int-euKJQV2sHmnOUSFPRw)."
  }
}

variable "gcp_organization_id" {
  description = "Numeric GCP organization ID. Scopes project discovery and grants org-level roles/browser."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.gcp_organization_id))
    error_message = "gcp_organization_id must be a numeric GCP organization ID."
  }
}

variable "service_account_project_id" {
  description = "GCP project ID where the service account will be created."
  type        = string
}

variable "project_ids" {
  description = "Explicit list of GCP project IDs to onboard. When null, auto-discovers all ACTIVE projects in the organization."
  type        = list(string)
  default     = null
}

variable "excluded_project_ids" {
  description = "Project IDs to exclude from auto-discovery. Ignored when project_ids is provided."
  type        = list(string)
  default     = []
}

variable "iam_readonly" {
  description = "Enable IAM read-only access for security review and audit logs."
  type        = bool
  default     = true
}

variable "secret_manager_readonly" {
  description = "Enable Secret Manager read-only access."
  type        = bool
  default     = true
}

variable "gcs_tf_state_readonly" {
  description = "Enable GCS read-only access for Terraform state file scanning."
  type        = bool
  default     = true
}

variable "vertex_agents_readonly" {
  description = "Enable Vertex AI read-only access for AI-agent discovery. Self-contained — also grants the IAM/logging/policy-analyzer read roles and APIs it needs, so it works independently of iam_readonly / enable_per_project_apis. Free: read roles only."
  type        = bool
  default     = true
}

variable "vertex_activity_readonly" {
  description = "Enable read access to Vertex AI agent-activity audit logs: creates a log view scoped to aiplatform Data Access entries and grants roles/logging.viewAccessor on that view only (no project-wide private-log read), and — with manage_vertex_audit_config — turns on Data Access audit logs for aiplatform.googleapis.com on monitored projects. Off by default: audit-log ingestion is billable. Requires vertex_agents_readonly, which discovers the agents the activity joins to."
  type        = bool
  default     = false
}

variable "manage_vertex_audit_config" {
  description = <<-EOT
    With vertex_activity_readonly, manage the aiplatform.googleapis.com audit
    config (DATA_READ) on monitored projects. Set to false to take the read
    grant without the module mutating audit configs (e.g. when Data Access
    logging is already enforced by org policy). NOTE: the audit config is
    authoritative for the aiplatform service — it replaces any pre-existing
    aiplatform audit config (other services are untouched), and disabling the
    toggle or destroying removes it entirely.
  EOT
  type        = bool
  default     = true
}

variable "exclude_non_agent_vertex_logs" {
  description = <<-EOT
    With vertex_activity_readonly, add a _Default-sink exclusion dropping the
    aiplatform Data Access entries Hush does not read, so they are not billed.
    MUST be false for anyone already collecting aiplatform Data Access logs
    (own audit config or org-wide allServices) — excluded entries are never
    stored and cannot be recovered.
  EOT
  type        = bool
  default     = true
}

variable "mcp_registry_readonly" {
  description = "Enable API Hub read-only access for MCP-registry discovery. Self-contained — also grants the IAM/logging/policy-analyzer read roles and APIs it needs, so it works independently of iam_readonly / enable_per_project_apis."
  type        = bool
  default     = true
}

variable "enable_per_project_apis" {
  description = <<-EOT
    Enable Policy Analyzer API on each monitored project. If apply fails with
    "Permission denied to list services" on some projects, set this to false
    and re-apply.
  EOT
  type        = bool
  default     = true
}

variable "artifact_registry_readonly" {
  description = "Enable Artifact Registry read-only access for container image scanning."
  type        = bool
  default     = true
}

variable "hush_service_account_email" {
  description = "Email of the Hush Security service account that will impersonate the onboarding SA."
  type        = string
  default     = "hushsecurity@hush-security-integration.iam.gserviceaccount.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.hush_service_account_email))
    error_message = "hush_service_account_email must be a valid email address."
  }
}
