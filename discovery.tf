data "google_projects" "org" {
  count  = var.project_ids == null ? 1 : 0
  filter = "parent.id:${var.gcp_organization_id} parent.type:organization lifecycleState:ACTIVE"
}

data "google_folders" "level1" {
  count     = var.project_ids == null ? 1 : 0
  parent_id = "organizations/${var.gcp_organization_id}"
}

data "google_folders" "level2" {
  for_each = var.project_ids == null ? {
    for f in data.google_folders.level1[0].folders : f.name => f.name
    if f.state == "ACTIVE"
  } : {}
  parent_id = each.value
}

# Projects directly under any discovered folder (levels 1-2).
data "google_projects" "in_folder" {
  for_each = var.project_ids == null ? toset(local.all_folder_numeric_ids) : []
  filter   = "parent.id:${each.value} parent.type:folder lifecycleState:ACTIVE"
}
