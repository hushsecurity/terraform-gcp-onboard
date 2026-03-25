data "google_projects" "active" {
  count  = var.project_ids == null ? 1 : 0
  filter = "parent.id:${var.gcp_organization_id} lifecycleState:ACTIVE"
}

module "project_onboard" {
  source   = "./modules/project_onboard"
  for_each = toset(local.target_project_ids)

  project_id = each.value
  iam_member = local.iam_member
  iam_roles  = local.iam_roles
}
