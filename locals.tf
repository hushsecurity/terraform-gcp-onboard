locals {
  # All folder resource names (e.g. "folders/123") discovered at levels 1-2.
  all_folder_resource_names = var.project_ids == null ? distinct(concat(
    [for f in data.google_folders.level1[0].folders : f.name if f.state == "ACTIVE"],
    flatten([
      for fs in values(data.google_folders.level2) : [
        for f in fs.folders : f.name if f.state == "ACTIVE"
      ]
    ]),
  )) : []

  # Numeric folder ids (e.g. "123") used for `parent.id:` filter on google_projects.
  all_folder_numeric_ids = [
    for n in local.all_folder_resource_names : trimprefix(n, "folders/")
  ]

  # Project discovery: explicit list or auto-discovered (minus exclusions).
  # Auto-discovery walks org + folders up to 2 levels deep.
  discovered_project_ids = var.project_ids == null ? distinct(concat(
    [for p in data.google_projects.org[0].projects : p.project_id],
    flatten([
      for ps in values(data.google_projects.in_folder) : [
        for p in ps.projects : p.project_id
      ]
    ]),
  )) : []

  target_project_ids = var.project_ids != null ? var.project_ids : [
    for id in local.discovered_project_ids : id
    if !contains(var.excluded_project_ids, id)
    && length(regexall("^sys-[0-9]+$", id)) == 0
  ]

  # Service account placement: always explicit (required variable)
  service_account_project_id = var.service_account_project_id

  # Service account naming — tied to Hush integration ID when provided, otherwise random
  service_account_id = var.hush_integration_id != null ? "hush-${lower(var.hush_integration_id)}" : "hush-${random_id.suffix[0].hex}"

  # Service account identity
  iam_member = "serviceAccount:${google_service_account.hush.email}"

  # APIs that must be enabled on every monitored project
  per_project_apis = distinct(concat(
    var.enable_per_project_apis ? [
      "monitoring.googleapis.com",
      "policyanalyzer.googleapis.com",
    ] : [],
    var.agents_readonly ? [
      "aiplatform.googleapis.com",
      "apihub.googleapis.com",
      # Also enabled so agents_readonly is self-contained when enable_per_project_apis is off.
      "policyanalyzer.googleapis.com",
    ] : [],
  ))

  # Build role list from feature toggles
  iam_roles = compact([
    "roles/cloudasset.viewer",
    var.iam_readonly ? "roles/iam.securityReviewer" : "",
    var.iam_readonly ? "roles/iam.roleViewer" : "",
    var.iam_readonly ? "roles/logging.viewer" : "",
    var.iam_readonly ? "roles/monitoring.viewer" : "",
    var.iam_readonly ? "roles/policyanalyzer.activityAnalysisViewer" : "",
    var.iam_readonly ? "roles/serviceusage.serviceUsageConsumer" : "",
    var.secret_manager_readonly ? "roles/secretmanager.viewer" : "",
    var.secret_manager_readonly ? "roles/secretmanager.secretAccessor" : "",
    var.gcs_tf_state_readonly ? "roles/storage.objectViewer" : "",
    var.artifact_registry_readonly ? "roles/artifactregistry.reader" : "",
    var.agents_readonly ? "roles/aiplatform.viewer" : "", # Vertex AI
    var.agents_readonly ? "roles/apihub.viewer" : "",     # API Hub
    var.agents_readonly ? "roles/serviceusage.serviceUsageConsumer" : "",
    # Also granted so agents_readonly is self-contained and works when iam_readonly
    # is off (deduped by compact/toset).
    var.agents_readonly ? "roles/iam.securityReviewer" : "",
    var.agents_readonly ? "roles/logging.viewer" : "",
    var.agents_readonly ? "roles/policyanalyzer.activityAnalysisViewer" : "",
  ])
}
