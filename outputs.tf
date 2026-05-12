output "service_account_email" {
  description = "Email of the Hush onboarding service account."
  value       = google_service_account.hush.email
}

output "service_account_id" {
  description = "Full resource ID of the Hush onboarding service account."
  value       = google_service_account.hush.id
}

output "onboarded_project_ids" {
  description = "List of GCP project IDs that were onboarded."
  value       = local.use_org_level ? local.target_project_ids : [for k, m in module.project_onboard : m.project_id]
}
