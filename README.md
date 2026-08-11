# Hush Security GCP Onboarding Terraform Module

Terraform module to integrate your GCP project(s) with Hush Security.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| google | >= 4.0 |
| random | >= 3.0 |

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

  service_account_project_id = "my-project-id"
  project_ids                = ["my-project-id"]
}
```

### Single Project with Hush Provider

Using the Hush Terraform provider to create the integration and onboard module together in a single apply.

```hcl
resource "hush_gcp_integration" "main" {
  name                  = "production-gcp"
  service_account_email = module.hush_security.service_account_email
}

module "hush_security" {
  source = "hushsecurity/onboard/gcp"

  hush_org_id         = "org-us1234567890abc"
  gcp_organization_id = "123456789012"

  service_account_project_id = "my-project-id"
  project_ids                = ["my-project-id"]
}
```

### Organization (Auto-Discover)

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

### Organization with Exclusions

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

### Customized — Disable Features

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
| service_account_project_id | GCP project ID where the service account will be created. | `string` | yes |
| gcp_organization_id | Numeric GCP organization ID. Scopes discovery and grants org-level roles/browser. | `string` | yes |

### Optional — Integration ID

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| hush_integration_id | Hush Security integration ID. When null, a unique service account name is generated automatically. | `string` | `null` | no |

### Project Selection

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_ids | Explicit list of project IDs to onboard. Null = auto-discover. | `list(string)` | `null` | no |
| excluded_project_ids | Projects to exclude from auto-discovery. | `list(string)` | `[]` | no |

### Feature Toggles

| Name | Description | IAM Roles | Type | Default |
|------|-------------|-----------|------|--------|
| iam_readonly | Enable IAM read-only access for security review and audit logs. | `roles/iam.securityReviewer`, `roles/iam.roleViewer`, `roles/logging.viewer` | `bool` | `true` |
| secret_manager_readonly | Enable Secret Manager read-only access. | `roles/secretmanager.viewer`, `roles/secretmanager.secretAccessor` | `bool` | `true` |
| gcs_tf_state_readonly | Enable GCS read-only access for Terraform state file scanning. | `roles/storage.objectViewer` | `bool` | `true` |
| artifact_registry_readonly | Enable Artifact Registry read-only access for container image scanning. | `roles/artifactregistry.reader` | `bool` | `true` |
| vertex_agents_readonly | Enable Vertex AI read-only access for AI-agent discovery. Self-contained — also grants the IAM/logging/policy-analyzer read roles and APIs it needs, so it works independently of `iam_readonly` / `enable_per_project_apis`. | `roles/aiplatform.viewer`, `roles/serviceusage.serviceUsageConsumer`, `roles/iam.securityReviewer`, `roles/logging.viewer`, `roles/policyanalyzer.activityAnalysisViewer` | `bool` | `true` |
| vertex_activity_readonly | Enable read access to Vertex AI agent-activity audit logs. Creates a log view scoped to aiplatform Data Access entries and grants access to **that view only** — no project-wide private-log read. With `manage_vertex_audit_config`, also turns on Data Access audit logs for `aiplatform.googleapis.com` plus a `_Default`-sink exclusion that drops the non-agent aiplatform entries before they are billed. **Off by default — audit-log ingestion is billable.** Requires `vertex_agents_readonly`. | `roles/logging.viewAccessor` (on the `hush-vertex-activity` view) | `bool` | `false` |
| manage_vertex_audit_config | Let the module manage the aiplatform audit config for `vertex_activity_readonly`. **The audit config is authoritative for the aiplatform service**: it replaces any pre-existing aiplatform audit config (other services untouched) and is removed on disable/destroy. Set to `false` to take only the read grant, e.g. when Data Access logging is enforced by org policy. | — | `bool` | `true` |
| exclude_non_agent_vertex_logs | Add a `_Default`-sink exclusion dropping the aiplatform Data Access entries Hush does not read, so they are not billed. **Set to `false` if you already collect aiplatform Data Access logs** (your own audit config or org-wide `allServices`) — excluded entries are never stored and cannot be recovered. | — | `bool` | `true` |

> Both mutations follow `enable_per_project_apis` and skip the service-account
> project, like the per-project APIs.
>
> Migrating from the gcloud onboarding script? It creates the same
> `hush-vertex-non-agent-data-access` exclusion, so terraform will fail with
> `alreadyExists` — import it first
> (`terraform import 'module.project_onboard["PROJECT"].google_logging_project_exclusion.vertex_non_agent_data_access[0] projects/PROJECT/exclusions/hush-vertex-non-agent-data-access'`)
> or delete it and let terraform recreate it.
| mcp_registry_readonly | Enable API Hub read-only access for MCP-registry discovery. Self-contained (same read roles/APIs as above). | `roles/apihub.viewer`, `roles/serviceusage.serviceUsageConsumer`, `roles/iam.securityReviewer`, `roles/logging.viewer`, `roles/policyanalyzer.activityAnalysisViewer` | `bool` | `true` |

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


Hush Security will use service account impersonation (keyless) to access the onboarded projects.

## License

Copyright Hush Security. All rights reserved.
