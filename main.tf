resource "random_id" "suffix" {
  count       = var.hush_integration_id == null ? 1 : 0
  byte_length = 5
}

module "project_onboard" {
  source   = "./modules/project_onboard"
  for_each = toset(local.target_project_ids)

  project_id    = each.value
  iam_member    = local.iam_member
  iam_roles     = local.iam_roles
  required_apis = each.value == local.service_account_project_id ? [] : local.per_project_apis
  # audit-config/exclusion mutations follow the same levers as the APIs: not
  # on the SA project, and not when enable_per_project_apis opts out of
  # touching monitored projects
  enable_vertex_audit_logs = (
    each.value != local.service_account_project_id
    && var.enable_per_project_apis
    && var.vertex_activity_readonly
    && var.manage_vertex_audit_config
  )
  create_vertex_billing_exclusion = (
    each.value != local.service_account_project_id
    && var.enable_per_project_apis
    && var.vertex_activity_readonly
    && var.exclude_non_agent_vertex_logs
  )
  # the read grant itself is scoped to a log view, so it is safe on every
  # monitored project including the service-account one
  grant_vertex_activity_read = var.vertex_activity_readonly
}
