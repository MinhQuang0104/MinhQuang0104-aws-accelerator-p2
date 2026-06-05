# K8s on AWS - Terraform 1-Click

Bài lab này dùng Terraform để tạo một EC2 Ubuntu 24.04 chạy Minikube bằng Docker
driver, triển khai nginx bằng `kubectl apply` qua SSH và public ứng dụng qua AWS
Application Load Balancer.

Luồng traffic:

```text
Internet -> ALB:80 -> EC2:30080 -> Minikube NodePort:30080 -> nginx Pod:80
```

## Điều Kiện Cần

- Terraform >= 1.6
- AWS credentials đã được cấu hình
- Một cặp SSH key có sẵn trên máy local
- Private key dùng cho Terraform không được bảo vệ bằng passphrase
- Public IP hiện tại của bạn ở định dạng CIDR, thông thường là `/32`

Sao chép `terraform.tfvars.example` thành `terraform.tfvars`, sau đó thay các giá
trị ví dụ bằng thông tin thực tế. Không commit private key hoặc file
`terraform.tfvars` chứa thông tin thật.

## Chạy Terraform

```bash
terraform init
terraform apply
```

Chỉ cần một lần apply từ trạng thái trống. Sau khi apply hoàn tất, Terraform chỉ
output DNS của ALB. ALB health check có thể cần một khoảng thời gian ngắn để đánh
dấu target là healthy.

## Thứ Tự Apply

1. Terraform tạo VPC, hai public subnet, route table và internet gateway.
2. Terraform tạo security group cho ALB và EC2.
3. Terraform tạo EC2 instance Ubuntu 24.04.
4. EC2 `user_data` cài Docker, kubectl và Minikube.
5. Minikube khởi động bằng Docker driver và publish NodePort ra EC2 host.
6. `null_resource.minikube_ready` kết nối SSH và chờ file
   `/tmp/minikube-ready`.
7. `null_resource.deploy_nginx` tải manifest lên EC2 và chạy `kubectl apply`.
8. Terraform chờ nginx Deployment rollout thành công.
9. ALB đăng ký EC2 vào Target Group sau khi NodePort Service tồn tại.

## Thành Phần Được Tạo

AWS Provider tạo:

- VPC `10.0.0.0/16`
- Hai public subnet ở hai Availability Zone
- Internet Gateway và public route table
- Security Group cho ALB và EC2
- AWS Key Pair
- EC2 Ubuntu 24.04 có public IP
- Application Load Balancer, Listener và Target Group

Null Provider tạo:

- Tài nguyên chờ Minikube Ready
- Tài nguyên triển khai nginx bằng `kubectl apply`

Manifest `nginx.yaml.tftpl` tạo:

- Namespace `nginx`
- Deployment dùng image `nginx:alpine`
- Service loại NodePort

## Bảo Mật Mạng

- ALB port `80` cho phép truy cập từ internet.
- EC2 port `22` chỉ cho phép truy cập từ `my_ip_cidr`.
- EC2 NodePort chỉ cho phép truy cập từ Security Group của ALB.
- Kubernetes API không cần public ra internet.

## Trade-Off Của Phương Án Một Lần Apply

Terraform quản lý `null_resource.deploy_nginx`, nhưng không quản lý trực tiếp
từng Kubernetes object như Kubernetes Provider. Nếu manifest thay đổi,
`manifest_sha256` làm cho resource được thay thế và `kubectl apply` chạy lại.

Phương án này ưu tiên yêu cầu một lần `terraform apply` và tránh giới hạn
lifecycle của Kubernetes Provider: provider cần kubeconfig trong giai đoạn plan,
trong khi kubeconfig chỉ tồn tại sau khi EC2 và Minikube đã khởi động.

Dự án sử dụng AWS Provider và Null Provider. Nếu challenge bắt buộc phải sử dụng
Kubernetes Provider hoặc Helm Provider, cần quay lại phương án hai giai đoạn
hoặc dùng một wrapper script chạy hai lần apply.

## Destroy

```bash
terraform destroy
```

Destroy provisioner sẽ chạy `kubectl delete` trước khi EC2 bị xóa. Nếu EC2 không
còn truy cập được, bước xóa manifest có thể thất bại; các Kubernetes object vẫn
sẽ biến mất khi EC2 bị xóa.

## Lỗi SSH Private Key Có Passphrase

Terraform `remote-exec` không thể nhập passphrase tương tác. Nếu gặp lỗi
`this private key is passphrase protected`, hãy dùng một private key riêng không
có passphrase cho lab. Không commit private key vào Git.
