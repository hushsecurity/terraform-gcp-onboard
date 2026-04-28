# When org_level_onboarding is true, grant all feature roles at the org level
# instead of per project.
resource "google_organization_iam_member" "hush_org_roles" {
  for_each = local.use_org_level ? toset(local.iam_roles) : toset([])

  org_id = var.gcp_organization_id
  role   = each.value
  member = local.iam_member
}

# Enable required APIs per project even in org-level mode, because GCP does
# not support org-level API activation.
resource "google_project_service" "org_level_per_project_apis" {
  for_each = local.use_org_level ? {
    for pair in setproduct(distinct(local.target_project_ids), local.per_project_apis) :
    "${pair[0]}/${pair[1]}" => { project = pair[0], service = pair[1] }
    if pair[0] != local.service_account_project_id
  } : {}

  project            = each.value.project
  service            = each.value.service
  disable_on_destroy = false
}

# Per-project onboarding: grant roles and enable APIs per project.
# Skipped when org_level_onboarding is true.
module "project_onboard" {
  source   = "./modules/project_onboard"
  for_each = local.use_org_level ? toset([]) : toset(local.target_project_ids)

  project_id    = each.value
  iam_member    = local.iam_member
  iam_roles     = local.iam_roles
  required_apis = each.value == local.service_account_project_id ? [] : local.per_project_apis
}
