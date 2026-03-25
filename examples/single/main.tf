module "hush_security" {
  source  = "hushsecurity/onboard/gcp"
  version = "~> 1.0" # Find the latest version at https://registry.terraform.io/modules/hushsecurity/onboard/gcp/latest

  hush_org_id         = var.hush_org_id
  hush_integration_id = var.hush_integration_id
  gcp_organization_id = var.gcp_organization_id

  service_account_project_id = var.project_id
  project_ids                = [var.project_id]
}
