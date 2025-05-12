# Cấu hình provider Google Cloud
provider "google" {
  project = "prj-tribvcloud"
  region  = "asia-southeast1"   # Thay bằng region bạn muốn sử dụng
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Tạo Google Cloud Storage Bucket
resource "google_storage_bucket" "my_bucket" {
  name          = "my-company-data-${random_id.bucket_suffix.hex}"
  location      = "ASIA-SOUTHEAST1"        # Region lưu trữ dữ liệu
  force_destroy = true                    # Khi true, xóa bucket ngay cả khi có dữ liệu

  # Cấu hình kiểm soát phiên bản
  versioning {
    enabled = true  # Bật phiên bản để lưu lịch sử các thay đổi
  }

  # Cấu hình vòng đời của đối tượng (tùy chọn)
  lifecycle_rule {
    condition {
      age = 365  # Số ngày
    }
    action {
      type = "Delete"  # Hành động: Delete hoặc SetStorageClass
    }
  }

  # Cấu hình lớp lưu trữ (storage class)
  storage_class = "STANDARD"  # STANDARD, NEARLINE, COLDLINE, ARCHIVE

  # Cấu hình bảo mật (tùy chọn)
  uniform_bucket_level_access = true  # Sử dụng IAM thay vì ACL
}

# Xuất URL của bucket (tùy chọn)
output "bucket_url" {
  value = google_storage_bucket.my_bucket.url
}
