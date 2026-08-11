resource "google_project_iam_member" "hush_roles" {
  for_each = toset(var.iam_roles)

  project = var.project_id
  role    = each.value
  member  = var.iam_member
}

resource "google_project_service" "per_project_apis" {
  for_each = toset(var.required_apis)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# Vertex agent invocations (QueryReasoningEngine) only surface as Data Access
# audit-log entries, and GCP keeps Data Access logs off by default. This is
# authoritative for the aiplatform service only: it replaces a pre-existing
# aiplatform audit config and is removed on destroy; other services' audit
# configs are untouched.
resource "google_project_iam_audit_config" "vertex_data_access" {
  count = var.enable_vertex_audit_logs ? 1 : 0

  project = var.project_id
  service = "aiplatform.googleapis.com"

  audit_log_config {
    log_type = "DATA_READ"
  }
}

# DATA_READ on aiplatform ingests every Vertex data-plane read (predictions,
# embeddings, model calls) while the feed consumes only the reasoning-engine
# query methods; drop the rest from the _Default sink before it is billed.
# Customer-defined sinks are unaffected. The spared methods must match the
# feed's read filter (argus/clients/gcp_logging.py METHOD_MARKERS — the
# source of truth, also rendered into mixer's onboarding script).
# Vertex agent activity reads Data Access entries, which are "private" — but
# roles/logging.privateLogViewer would grant read on every service's Data
# Access logs in the project (Secret Manager, GCS, BigQuery, IAM). A log view
# filtered to aiplatform plus roles/logging.viewAccessor on that view alone is
# enough to read them: entries.list resolves a project-scope query through the
# views the caller can access, so nothing outside this slice is readable.
# View filters accept only log source / resource type / labels / log id —
# protoPayload fields (e.g. methodName) are rejected, so the view scopes to
# the service and the feed filters to its methods at read time.
resource "google_logging_log_view" "vertex_activity" {
  count = var.grant_vertex_activity_read ? 1 : 0

  name        = "hush-vertex-activity"
  parent      = "projects/${var.project_id}"
  bucket      = "projects/${var.project_id}/locations/global/buckets/_Default"
  description = "Vertex AI agent-activity audit entries readable by Hush"
  filter      = <<-EOT
    LOG_ID("cloudaudit.googleapis.com/data_access")
    AND resource.type="audited_resource"
    AND resource.labels.service="aiplatform.googleapis.com"
  EOT
}

resource "google_logging_log_view_iam_member" "hush_vertex_activity" {
  count = var.grant_vertex_activity_read ? 1 : 0

  parent   = google_logging_log_view.vertex_activity[0].parent
  location = google_logging_log_view.vertex_activity[0].location
  bucket   = google_logging_log_view.vertex_activity[0].bucket
  name     = google_logging_log_view.vertex_activity[0].name
  role     = "roles/logging.viewAccessor"
  member   = var.iam_member
}

resource "google_logging_project_exclusion" "vertex_non_agent_data_access" {
  count = var.create_vertex_billing_exclusion ? 1 : 0

  project     = var.project_id
  name        = "hush-vertex-non-agent-data-access"
  description = "Drops aiplatform Data Access entries that Hush agent-activity monitoring does not read, so they are not billed."
  filter      = <<-EOT
    logName="projects/${var.project_id}/logs/cloudaudit.googleapis.com%2Fdata_access"
    AND protoPayload.serviceName="aiplatform.googleapis.com"
    AND NOT protoPayload.methodName:"ReasoningEngineExecutionService.QueryReasoningEngine"
    AND NOT protoPayload.methodName:"ReasoningEngineExecutionService.StreamQueryReasoningEngine"
  EOT
}
