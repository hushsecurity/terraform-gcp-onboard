resource "google_service_account" "hush" {
  account_id   = local.service_account_id
  display_name = "Hush Security"
  description  = "Integration with Hush Security (${var.hush_org_id} / ${var.hush_integration_id})"
  project      = local.service_account_project_id

  lifecycle {
    precondition {
      condition     = local.service_account_project_id != null
      error_message = "Cannot determine service account project. Provide service_account_project_id, or ensure at least one project is discovered or specified via project_ids."
    }
    precondition {
      condition     = length(local.target_project_ids) > 0
      error_message = "No target projects resolved. When using auto-discovery, verify that gcp_organization_id is correct and the caller has roles/browser on the organization. When using project_ids, ensure the list is not empty."
    }
  }
}

resource "google_service_account_iam_member" "hush_impersonation" {
  service_account_id = google_service_account.hush.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${var.hush_service_account_email}"
}

resource "google_organization_iam_member" "browser" {
  count  = var.gcp_organization_id != null ? 1 : 0
  org_id = var.gcp_organization_id
  role   = "roles/browser"
  member = local.iam_member
}

resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "cloudasset.googleapis.com",
  ])

  project            = local.service_account_project_id
  service            = each.value
  disable_on_destroy = false
}
