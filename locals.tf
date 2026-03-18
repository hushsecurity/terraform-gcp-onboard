locals {
  # Project discovery: explicit list or auto-discovered (minus exclusions)
  discovered_project_ids = var.project_ids == null ? [
    for p in data.google_projects.active[0].projects : p.project_id
    if !contains(var.excluded_project_ids, p.project_id)
  ] : []

  target_project_ids = var.project_ids != null ? var.project_ids : local.discovered_project_ids

  # Service account placement: explicit or first target project
  service_account_project_id = coalesce(var.service_account_project_id, local.target_project_ids[0])

  # Service account naming — tied to Hush integration ID
  # lower() required: GCP account_id must be lowercase, integration IDs may contain uppercase
  service_account_id = "hush-${lower(var.hush_integration_id)}"

  # Service account identity
  iam_member = "serviceAccount:${google_service_account.hush.email}"

  # Build role list from feature toggles
  iam_roles = compact([
    "roles/cloudasset.viewer",
    var.iam_readonly ? "roles/iam.securityReviewer" : "",
    var.iam_readonly ? "roles/iam.roleViewer" : "",
    var.iam_readonly ? "roles/logging.viewer" : "",
    var.secret_manager_readonly ? "roles/secretmanager.viewer" : "",
    var.secret_manager_readonly ? "roles/secretmanager.secretAccessor" : "",
    var.gcs_tf_state_readonly ? "roles/storage.objectViewer" : "",
    var.artifact_registry_readonly ? "roles/artifactregistry.reader" : "",
  ])
}
