data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# --- KHỐI OUTPUT ĐÃ SỬA CÚ PHÁP ---

# output "account_identity" {
#   # Tham chiếu đến data source aws_caller_identity có tên là current
#   value = data.aws_caller_identity.current
# }

# output "az_available" {
#   # Tham chiếu đến data source aws_availability_zones có tên là available
#   value = data.aws_availability_zones.available
# }

# output "latest_al2023_ami" {
#   # Tham chiếu đến thuộc tính id của data source aws_ami có tên là al2023
#   value = data.aws_ami.al2023.id 
# }


variable "allowed_ports" {
  type    = list(number)
  default = [80, 443, 22]
}

locals {
  # list: lấy các cổng, lọc bỏ 22 bằng mệnh đề if
  web_ports = [for p in var.allowed_ports : p if p != 22]

  # map: cổng -> mô tả
  port_desc = { for p in var.allowed_ports : p => "cho phép cổng ${p}" }
}
# 1. In ra giá trị của variable allowed_ports
# output "in_danh_sach_ports_goc" {
#   value       = var.allowed_ports
#   description = "Danh sách các cổng đầu vào ban đầu"
# }

# # 2. In ra giá trị của local web_ports (sau khi đã lọc bỏ cổng 22)
# output "in_ports_da_loc" {
#   value       = local.web_ports
#   description = "Danh sách cổng web sau khi dùng vòng lặp for để lọc"
# }

# # 3. In ra giá trị của local port_desc (dạng map)
# output "in_ban_do_mo_ta_ports" {
#   value       = local.port_desc
#   description = "Map ánh xạ từ số cổng sang chuỗi mô tả"
# }