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
