resource "google_project_iam_member" "hush_roles" {
  for_each = toset(var.iam_roles)

  project = var.project_id
  role    = each.value
  member  = var.iam_member
}
