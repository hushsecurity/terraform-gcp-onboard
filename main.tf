module "project_onboard" {
  source   = "./modules/project_onboard"
  for_each = toset(local.target_project_ids)

  project_id    = each.value
  iam_member    = local.iam_member
  iam_roles     = local.iam_roles
  required_apis = each.value == local.service_account_project_id ? [] : local.per_project_apis
}
