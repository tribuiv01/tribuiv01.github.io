# Cấu hình provider Google Cloud
provider "google" {
  project = "prj-tribvcloud"
  region  = "asia-southeast1"  # Thay bằng region bạn muốn sử dụng
}

# Tạo DNS Managed Zone (Public) cho gcp.tribv.cloud
resource "google_dns_managed_zone" "public_zone" {
  name        = "gcp-tribv-cloud-zone"  # Tên không chứa dấu chấm và ký tự đặc biệt
  dns_name    = "gcp.tribv.cloud."      # Lưu ý dấu chấm ở cuối là bắt buộc
  description = "Public DNS zone for gcp.tribv.cloud"
  
  # Cấu hình cho public zone
  visibility = "public"
  
  # Cấu hình DNSSEC (tùy chọn)
  dnssec_config {
    state = "on"
  }
  
  # Labels (tùy chọn)
  labels = {
    environment = "production"
    managed_by  = "terraform"
  }
}

# Tạo DNS Managed Zone (Private) cho internal.gcp.tribv.cloud
resource "google_dns_managed_zone" "private_zone" {
  name        = "internal-gcp-tribv-cloud-zone"
  dns_name    = "internal.gcp.tribv.cloud."  # Lưu ý dấu chấm ở cuối là bắt buộc
  description = "Private DNS zone for internal services"
  
  # Cấu hình cho private zone
  visibility = "private"
  
  # Chỉ định VPC networks có thể truy cập private zone này
  private_visibility_config {
    networks {
      network_url = "projects/prj-tribvcloud/global/networks/default"
      # Thay thế bằng VPC network của bạn
    }
  }
  
  labels = {
    environment = "development"
    managed_by  = "terraform"
  }
}

# Tạo A Record trong Public Zone
resource "google_dns_record_set" "a_record" {
  name         = "www.gcp.tribv.cloud."  # Lưu ý dấu chấm ở cuối là bắt buộc
  managed_zone = google_dns_managed_zone.public_zone.name
  type         = "A"
  ttl          = 300  # Thời gian sống (seconds)
  
  rrdatas = ["203.0.113.1"]  # Thay bằng IP thực tế của bạn
}

# Tạo MX Record cho email
resource "google_dns_record_set" "mx_record" {
  name         = "gcp.tribv.cloud."  # Lưu ý dấu chấm ở cuối là bắt buộc
  managed_zone = google_dns_managed_zone.public_zone.name
  type         = "MX"
  ttl          = 3600
  
  rrdatas = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com.",
    "10 alt4.aspmx.l.google.com."
  ]
}

# Tạo CNAME Record
resource "google_dns_record_set" "cname_record" {
  name         = "blog.gcp.tribv.cloud."  # Lưu ý dấu chấm ở cuối là bắt buộc
  managed_zone = google_dns_managed_zone.public_zone.name
  type         = "CNAME"
  ttl          = 300
  
  rrdatas = ["ghs.googlehosted.com."]  # Thay bằng hostname thực tế
}

# Tạo TXT Record (thường dùng cho xác thực domain)
resource "google_dns_record_set" "txt_record" {
  name         = "gcp.tribv.cloud."  # Lưu ý dấu chấm ở cuối là bắt buộc
  managed_zone = google_dns_managed_zone.public_zone.name
  type         = "TXT"
  ttl          = 300
  
  rrdatas = [
    "\"v=spf1 include:_spf.google.com ~all\"",  # SPF record
    "\"google-site-verification=abcdefghijklmnopqrstuvwxyz\""  # Xác thực Google (thay bằng mã xác thực thực tế)
  ]
}

# Tạo NS Record cho subdomain
resource "google_dns_record_set" "ns_record" {
  name         = "subdomain.gcp.tribv.cloud."  # Lưu ý dấu chấm ở cuối là bắt buộc
  managed_zone = google_dns_managed_zone.public_zone.name
  type         = "NS"
  ttl          = 21600  # 6 giờ
  
  rrdatas = [
    "ns-cloud-a1.googledomains.com.",
    "ns-cloud-a2.googledomains.com.",
    "ns-cloud-a3.googledomains.com.",
    "ns-cloud-a4.googledomains.com."
  ]
}

# Tạo A Record trong Private Zone
resource "google_dns_record_set" "private_a_record" {
  name         = "db.internal.gcp.tribv.cloud."  # Lưu ý dấu chấm ở cuối là bắt buộc
  managed_zone = google_dns_managed_zone.private_zone.name
  type         = "A"
  ttl          = 300
  
  rrdatas = ["10.0.0.10"]  # IP nội bộ
}

# Xuất thông tin name servers (tùy chọn)
output "public_zone_name_servers" {
  description = "Name servers cho public zone"
  value       = google_dns_managed_zone.public_zone.name_servers
}

output "private_zone_name" {
  description = "Tên của private zone"
  value       = google_dns_managed_zone.private_zone.name
}
