output "service_account_email" {
  description = "Email of the Hush onboarding service account."
  value       = module.hush_security.service_account_email
}
