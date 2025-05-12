# Cấu hình provider Google Cloud
provider "google" {
  project = "prj-tribvcloud"
  region  = "asia-southeast1"  # Thay bằng region bạn muốn sử dụng
}

# Biến để dễ dàng quản lý
variable "project_id" {
  description = "ID của project GCP"
  type        = string
  default     = "prj-tribvcloud"  # Thay bằng project ID của bạn
}

variable "service_accounts" {
  description = "Danh sách các service account cần tạo"
  type = map(object({
    display_name = string
    description  = string
    roles        = list(string)
  }))
  default = {
    "terraform-sa" = {
      display_name = "Terraform Service Account"
      description  = "Service account dùng cho Terraform automation"
      roles = [
        "roles/dns.admin",
        "roles/compute.networkAdmin",
        "roles/iam.serviceAccountUser",
        "roles/storage.admin"
      ]
    },
    "gke-sa" = {
      display_name = "GKE Service Account"
      description  = "Service account dùng cho GKE clusters"
      roles = [
        "roles/container.admin",
        "roles/storage.objectViewer"
      ]
    }
  }
}

variable "custom_roles" {
  description = "Danh sách các custom role cần tạo"
  type = map(object({
    title       = string
    description = string
    permissions = list(string)
  }))
  default = {
    "customDnsAdmin" = {
      title       = "Custom DNS Administrator"
      description = "Custom role với quyền quản lý DNS"
      permissions = [
        "dns.managedZones.create",
        "dns.managedZones.delete",
        "dns.managedZones.get",
        "dns.managedZones.list",
        "dns.managedZones.update",
        "dns.networks.bindPrivateDNSZone",
        "dns.policies.create",
        "dns.policies.delete",
        "dns.policies.get",
        "dns.policies.list",
        "dns.policies.update",
        "dns.projects.get",
        "dns.resourceRecordSets.create",
        "dns.resourceRecordSets.delete",
        "dns.resourceRecordSets.get",
        "dns.resourceRecordSets.list",
        "dns.resourceRecordSets.update"
      ]
    }
  }
}

# Tạo service accounts
resource "google_service_account" "service_accounts" {
  for_each     = var.service_accounts
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
  project      = var.project_id
}

# Tạo custom roles ở cấp project
resource "google_project_iam_custom_role" "custom_roles" {
  for_each    = var.custom_roles
  role_id     = each.key
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  project     = var.project_id
}

# Gán roles cho các service accounts
resource "google_project_iam_member" "service_account_roles" {
  for_each = {
    for pair in flatten([
      for sa_key, sa in var.service_accounts : [
        for role in sa.roles : {
          sa_key = sa_key
          role   = role
        }
      ]
    ]) : "${pair.sa_key}-${pair.role}" => pair
  }
  
  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.service_accounts[each.value.sa_key].email}"
}

# Gán custom role cho service account cụ thể
resource "google_project_iam_member" "custom_role_assignment" {
  for_each = google_project_iam_custom_role.custom_roles
  
  project = var.project_id
  role    = "projects/${var.project_id}/roles/${each.key}"
  member  = "serviceAccount:${google_service_account.service_accounts["terraform-sa"].email}"
}

# Tạo key cho service account (thận trọng khi sử dụng)
resource "google_service_account_key" "terraform_sa_key" {
  service_account_id = google_service_account.service_accounts["terraform-sa"].name
}

# Xuất key dưới dạng base64 (thận trọng khi sử dụng)
output "terraform_sa_key" {
  value     = google_service_account_key.terraform_sa_key.private_key
  sensitive = true
}

# Quản lý IAM policy cho một resource cụ thể (ví dụ: bucket)
resource "google_storage_bucket" "example_bucket" {
  name     = "example-bucket-${var.project_id}"  # Đảm bảo tên bucket là duy nhất
  location = "ASIA"
}

resource "google_storage_bucket_iam_binding" "bucket_admin" {
  bucket = google_storage_bucket.example_bucket.name
  role   = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.service_accounts["terraform-sa"].email}",
  ]
}

# Quản lý IAM policy cho toàn bộ project
resource "google_project_iam_binding" "project_owners" {
  project = var.project_id
  role    = "roles/owner"
  members = [
    "user:admin@tribv.cloud",  # Thay bằng email của bạn
  ]
}

# Tạo IAM policy cho một folder
resource "google_folder_iam_policy" "folder_policy" {
  folder      = "folders/123456789"  # Thay bằng ID folder thực tế
  policy_data = data.google_iam_policy.folder_policy.policy_data
}

data "google_iam_policy" "folder_policy" {
  binding {
    role = "roles/resourcemanager.folderAdmin"
    members = [
      "serviceAccount:${google_service_account.service_accounts["terraform-sa"].email}",
    ]
  }
  
  binding {
    role = "roles/resourcemanager.folderViewer"
    members = [
      "serviceAccount:${google_service_account.service_accounts["gke-sa"].email}",
    ]
  }
}

# Tạo IAM policy cho một organization
resource "google_organization_iam_binding" "organization_admin" {
  org_id = "624273055560"  # Thay bằng ID organization thực tế
  role   = "roles/resourcemanager.organizationAdmin"
  members = [
    "user:tribuiv01@gmail.com",  # Thay bằng email admin thực tế
  ]
}

# Gán quyền cho một nhóm người dùng
resource "google_project_iam_binding" "project_viewers" {
  project = var.project_id
  role    = "roles/viewer"
  members = [
    "group:admin@tribv.cloud",  # Thay bằng email group thực tế
  ]
}

# Tạo workload identity federation (cho CI/CD từ GitHub Actions)
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Identity Pool"
  description               = "Identity pool for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Actions Provider"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Xuất thông tin hữu ích
output "service_account_emails" {
  value = {
    for key, sa in google_service_account.service_accounts : key => sa.email
  }
}

output "custom_roles" {
  value = {
    for key, role in google_project_iam_custom_role.custom_roles : key => role.id
  }
}

output "workload_identity_pool" {
  value = google_iam_workload_identity_pool.github_pool.name
}
