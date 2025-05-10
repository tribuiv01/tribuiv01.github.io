variable "ssh_user" {
  description = "Username cho SSH"
  type        = string
  default     = "your_username"  # Thay thế bằng username bạn muốn sử dụng
}

variable "ssh_pub_key_file" {
  description = "Đường dẫn tới file public key SSH"
  type        = string
  default     = "~/.ssh/id_rsa.pub"  # Hoặc đường dẫn tới file public key của bạn
}
