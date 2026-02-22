module "hush_security" {
  source  = "hushsecurity/onboard/gcp"
  version = "~> 1.0" # Find the latest version at https://registry.terraform.io/modules/hushsecurity/onboard/gcp/latest

  hush_org_id         = var.hush_org_id
  hush_integration_id = var.hush_integration_id
  gcp_organization_id = var.gcp_organization_id

  # project_ids is null by default → auto-discovery enabled
}
