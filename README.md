# Hush Security GCP Onboarding Terraform Module

Terraform module to integrate your GCP project(s) with Hush Security.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| google | >= 4.0 |

## Deployment Modes

This module supports two deployment modes:

- **Project-level onboarding**: Grant required roles per project. You can specify the projects explicitly (`project_ids`), or let the module auto-discover all active projects in the organization at onboarding time.
- **Org-level onboarding**: Grant all required roles at the organization level (all projects under the org). Set `org_level_onboarding = true` to use this mode.

## Usage

### Org-Level Onboarding

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/gcp"

  hush_org_id         = "org-us1234567890abc"
  hush_integration_id = "int-euKJQV2sHmnOUSFPRw"
  gcp_organization_id = "123456789012"

  service_account_project_id = "my-admin-project"
  org_level_onboarding       = true
}
```

### Org-Level Onboarding with Excluded Projects

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/gcp"

  hush_org_id         = "org-us1234567890abc"
  hush_integration_id = "int-euKJQV2sHmnOUSFPRw"
  gcp_organization_id = "123456789012"

  service_account_project_id = "my-admin-project"
  excluded_project_ids       = ["sandbox-project", "temp-project"]
  org_level_onboarding       = true
}
```

### Project-Level Onboarding, Single Project

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/gcp"

  hush_org_id         = "org-us1234567890abc"
  hush_integration_id = "int-euKJQV2sHmnOUSFPRw"
  gcp_organization_id = "123456789012"

  service_account_project_id = "my-project-id"
  project_ids                = ["my-project-id"]
}
```

### Project-Level Onboarding, Auto-Discover

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/gcp"

  hush_org_id         = "org-us1234567890abc"
  hush_integration_id = "int-euKJQV2sHmnOUSFPRw"
  gcp_organization_id = "123456789012"

  service_account_project_id = "my-admin-project"

  # project_ids is null by default — discovers all active projects in the org
}
```

### Project-Level Onboarding with Excluded Projects

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/gcp"

  hush_org_id         = "org-us1234567890abc"
  hush_integration_id = "int-euKJQV2sHmnOUSFPRw"
  gcp_organization_id = "123456789012"

  service_account_project_id = "my-admin-project"
  excluded_project_ids       = ["sandbox-project", "temp-project"]
}
```

### Customized -- Disable Features

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/gcp"

  hush_org_id         = "org-us1234567890abc"
  hush_integration_id = "int-euKJQV2sHmnOUSFPRw"
  gcp_organization_id = "123456789012"

  service_account_project_id = "my-project-id"
  project_ids                = ["my-project-id"]

  # Disable features you don't need
  secret_manager_readonly     = false
  artifact_registry_readonly  = false
}
```

## Inputs

### Required Variables

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| hush_org_id | Your Hush Security organization ID. | `string` | yes |
| hush_integration_id | Your Hush Security integration ID. | `string` | yes |
| service_account_project_id | GCP project ID where the service account will be created. | `string` | yes |
| gcp_organization_id | Numeric GCP organization ID. Scopes discovery and grants org-level roles/browser. | `string` | yes |

### Onboarding Mode

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| org_level_onboarding | If true, grant all required roles at the organization level instead of per project. | `bool` | `false` | no |

### Project Selection

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_ids | Explicit list of project IDs to onboard. Null = auto-discover. | `list(string)` | `null` | no |
| excluded_project_ids | Projects to exclude from auto-discovery. | `list(string)` | `[]` | no |

### Feature Toggles

| Name | Description | IAM Roles | Type | Default |
|------|-------------|-----------|------|--------|
| iam_readonly | Enable IAM read-only access for security review and audit logs. | `roles/iam.securityReviewer`, `roles/iam.roleViewer`, `roles/logging.viewer`, `roles/monitoring.viewer`, `roles/policyanalyzer.activityAnalysisViewer`, `roles/serviceusage.serviceUsageConsumer` | `bool` | `true` |
| secret_manager_readonly | Enable Secret Manager read-only access. | `roles/secretmanager.viewer`, `roles/secretmanager.secretAccessor` | `bool` | `true` |
| gcs_tf_state_readonly | Enable GCS read-only access for Terraform state file scanning. | `roles/storage.objectViewer` | `bool` | `true` |
| artifact_registry_readonly | Enable Artifact Registry read-only access for container image scanning. | `roles/artifactregistry.reader` | `bool` | `true` |

> `roles/cloudasset.viewer` and org-level `roles/browser` are always granted.

### Overrides

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| hush_service_account_email | Email of the Hush SA for impersonation. | `string` | `"hushsecurity@hush-security-integration.iam.gserviceaccount.com"` | no |

## Outputs

| Name | Description |
|------|-------------|
| service_account_email | Email of the Hush onboarding service account. |
| service_account_id | Full resource ID of the service account. |
| onboarded_project_ids | List of project IDs that were onboarded. |

## Integration

1. In the Hush Security dashboard, go to Integrations > GCP and create a new integration.
2. Copy the Terraform snippet into your TF configuration.
3. Run `terraform apply` to provision the service account and IAM bindings.
4. Copy the `service_account_email` output and provide it in Hush Security UI to complete the integration.


If `org_level_onboarding` is true, all required roles are granted at the organization level. Otherwise, roles are granted per project (least-privilege).

Hush Security will use service account impersonation (keyless) to access the onboarded projects.

## License

Copyright Hush Security. All rights reserved.
