# Cấu hình provider Google Cloud
provider "google" {
  project = "prj-tribvcloud"
  region  = "asia-southeast1"   # Thay bằng region bạn muốn sử dụng
}

# Tạo Artifact Registry repository
resource "google_artifact_registry_repository" "my_repo" {
  location      = "asia-southeast1"  # Khu vực lưu trữ repository
  repository_id = "my-docker-repo"   # ID của repository
  description   = "Docker repository cho ứng dụng của công ty"
  format        = "DOCKER"           # Format: DOCKER, NPM, PYTHON, MAVEN, APT, YUM, GO, HELM...

  # Cấu hình lưu trữ (không bắt buộc)
  kms_key_name = null  # Để null sẽ sử dụng mã hóa mặc định của Google

  # Cấu hình cleanup policies (tùy chọn - chỉ áp dụng cho một số định dạng)

  cleanup_policies {
    id     = "delete-old-versions"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "2592000s"  # Xóa các phiên bản không có tag và cũ hơn 30 ngày
    }
  }

  # Cấu hình mode (tùy chọn)
  mode = "STANDARD_REPOSITORY"  # STANDARD_REPOSITORY hoặc REMOTE_REPOSITORY
}

# Tạo IAM policy cho repository (tùy chọn)
# resource "google_artifact_registry_repository_iam_member" "repo_iam" {
#   project    = google_artifact_registry_repository.my_repo.project
#   location   = google_artifact_registry_repository.my_repo.location
#   repository = google_artifact_registry_repository.my_repo.name
#   role       = "roles/artifactregistry.reader"
#   member     = "serviceAccount:your-service-account@your-project-id.iam.gserviceaccount.com"
  
#   # Thay thế bằng service account hoặc group mà bạn muốn cấp quyền
#   # Ví dụ: "serviceAccount:my-sa@my-project.iam.gserviceaccount.com"
#   # Hoặc: "group:devops@example.com"
# }

# Xuất thông tin repository (tùy chọn)
output "repository_id" {
  value = google_artifact_registry_repository.my_repo.repository_id
}

output "repository_url" {
  value = "${google_artifact_registry_repository.my_repo.location}-docker.pkg.dev/${google_artifact_registry_repository.my_repo.project}/${google_artifact_registry_repository.my_repo.repository_id}"
}
