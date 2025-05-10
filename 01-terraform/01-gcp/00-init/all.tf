resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",          # Compute Engine API
    "iam.googleapis.com",              # Identity and Access Management API
    "cloudresourcemanager.googleapis.com", # Cloud Resource Manager API
    "serviceusage.googleapis.com",     # Service Usage API
    "servicenetworking.googleapis.com", # Service Networking API
    "dns.googleapis.com",
    "networkconnectivity.googleapis.com",
    "container.googleapis.com"
  ])
  
  project = "prj-tribvcloud"
  service = each.key
  
  disable_dependent_services = false
  disable_on_destroy         = false
}
