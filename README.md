# Hush Security GCP Onboarding Terraform Module

Terraform module to integrate your GCP project(s) with Hush Security.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| google | >= 4.0 |

## Deployment Modes

This module supports two deployment modes:

- **Single Project**: Onboard a specific GCP project by providing its ID.
- **Organization**: Auto-discover and onboard all active projects under a GCP organization.

## Usage

### Single Project (Explicit)

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/gcp"

  hush_org_id         = "org-us1234567890abc"
  hush_integration_id = "int-euKJQV2sHmnOUSFPRw"
  gcp_organization_id = "123456789012"

  project_ids = ["my-project-id"]
}
```

### Organization (Auto-Discover)

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/gcp"

  hush_org_id         = "org-us1234567890abc"
  hush_integration_id = "int-euKJQV2sHmnOUSFPRw"
  gcp_organization_id = "123456789012"

  # project_ids is null by default — discovers all active projects in the org
}
```

### Organization with Exclusions

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/gcp"

  hush_org_id         = "org-us1234567890abc"
  hush_integration_id = "int-euKJQV2sHmnOUSFPRw"
  gcp_organization_id = "123456789012"

  excluded_project_ids = ["sandbox-project", "temp-project"]
}
```

### Customized — Disable Features

```hcl
module "hush_security" {
  source = "hushsecurity/onboard/gcp"

  hush_org_id         = "org-us1234567890abc"
  hush_integration_id = "int-euKJQV2sHmnOUSFPRw"
  gcp_organization_id = "123456789012"

  project_ids = ["my-project-id"]

  # Disable features you don't need
  secret_manager_readonly     = false
  artifact_registry_readonly  = false
}
```

## Required Permissions

The Terraform caller (user or service account running `terraform apply`) needs the following permissions:

### On the service account project

The project where the Hush service account is created (defaults to the first target project, or `service_account_project_id` if set).

| Permission | Typical Role |
|---|---|
| `iam.serviceAccounts.create` | `roles/iam.serviceAccountAdmin` |
| `serviceusage.services.enable` | `roles/serviceusage.serviceUsageAdmin` |

### On each target project

| Permission | Typical Role |
|---|---|
| `resourcemanager.projects.getIamPolicy` | `roles/resourcemanager.projectIamAdmin` |
| `resourcemanager.projects.setIamPolicy` | `roles/resourcemanager.projectIamAdmin` |

### On the organization

| Permission | Typical Role |
|---|---|
| `resourcemanager.organizations.getIamPolicy` | `roles/resourcemanager.organizationAdmin` |
| `resourcemanager.organizations.setIamPolicy` | `roles/resourcemanager.organizationAdmin` |
| `resourcemanager.projects.list` | `roles/browser` (for auto-discovery) |

> **Tip**: For auto-discovery mode (when `project_ids` is not set), the caller also needs `resourcemanager.projects.list` at the org level to discover active projects.

## Inputs

### Required Variables

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| hush_org_id | Your Hush Security organization ID. | `string` | yes |
| hush_integration_id | Your Hush Security integration ID. | `string` | yes |
| gcp_organization_id | Numeric GCP organization ID. Scopes discovery and grants org-level browser. | `string` | yes |

### Project Selection

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| service_account_project_id | Project to host the SA. Defaults to first target project. | `string` | `null` | no |
| project_ids | Explicit list of project IDs to onboard. Null = auto-discover all active projects in the org. | `list(string)` | `null` | no |
| excluded_project_ids | Projects to exclude from auto-discovery. | `list(string)` | `[]` | no |

### Feature Toggles

| Name | Description | IAM Roles | Type | Default |
|------|-------------|-----------|------|--------|
| iam_readonly | Enable IAM read-only access for security review and audit logs. | `roles/iam.securityReviewer`, `roles/iam.roleViewer`, `roles/logging.viewer` | `bool` | `true` |
| secret_manager_readonly | Enable Secret Manager read-only access. | `roles/secretmanager.viewer`, `roles/secretmanager.secretAccessor` | `bool` | `true` |
| gcs_tf_state_readonly | Enable GCS read-only access for Terraform state file scanning. | `roles/storage.objectViewer` | `bool` | `true` |
| artifact_registry_readonly | Enable Artifact Registry read-only access for container image scanning. | `roles/artifactregistry.reader` | `bool` | `true` |

> `roles/cloudasset.viewer` is always granted. Org-level `roles/browser` is granted when using auto-discovery (`project_ids` is not set).

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

After deploying:

1. Copy the `service_account_email` output
2. In the Hush Security dashboard, go to Integrations > GCP
3. Create a new integration using the service account email

Hush Security will use service account impersonation (keyless) to access the onboarded projects.

## License

Copyright Hush Security. All rights reserved.
