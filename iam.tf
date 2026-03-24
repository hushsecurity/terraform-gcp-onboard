resource "google_service_account" "hush" {
  account_id   = local.service_account_id
  display_name = "Hush Security"
  description  = "Integration with Hush Security (${var.hush_org_id} / ${var.hush_integration_id})"
  project      = local.service_account_project_id

  lifecycle {
    prevent_destroy = true
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
