# Hướng Dẫn Triển Khai Lab AWS Macie với Terraform

## Tổng Quan

Dự án này cung cấp Infrastructure as Code (IaC) để triển khai bài lab "Phát hiện dữ liệu nhạy cảm trong Amazon S3 buckets và gửi thông báo sử dụng Amazon Macie" bằng Terraform.

## Kiến Trúc Hệ Thống

```
Người dùng
    ↓
    ├─→ Upload file mẫu (chứa PII) vào S3 Bucket
    │
    ├─→ Amazon Macie Job (quét S3)
    │       ↓
    │   Phát hiện dữ liệu nhạy cảm (Findings)
    │       ↓
    │
    ├─→ EventBridge Rule (bắt Findings)
    │       ↓
    │
    └─→ Amazon SNS Topic
            ↓
        Email Alert đến hộp thư người dùng
```

## Yêu Cầu Tiền Để

1. **AWS Account**: Tài khoản AWS hoạt động
2. **Terraform**: Phiên bản 1.0 hoặc cao hơn
3. **AWS CLI**: Cấu hình credentials (tùy chọn nhưng khuyến nghị)
4. **Email**: Địa chỉ email hợp lệ để nhận thông báo SNS

## Chuẩn Bị

### Bước 1: Cấu Hình Biến (Variables)

1. Copy file ví dụ:
```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Mở `terraform.tfvars` và chỉnh sửa:
   - **Bắt buộc**: Thay thế `your-email@example.com` bằng email thực tế của bạn
   - **Tùy chọn**: Thay đổi `aws_region` nếu cần (mặc định: ap-southeast-1)

Ví dụ:
```hcl
email_address = "your-actual-email@example.com"
aws_region    = "ap-southeast-1"
enable_macie_job = true
```

## Triển Khai (Deployment)

### Bước 2: Khởi Tạo Terraform

```bash
cd "Detect Sensitive data in Amazon S3 buckets and sent notifications using Amazon Macie"
terraform init
```

Lệnh này sẽ:
- Tải AWS Provider plugin
- Tạo thư mục `.terraform/`
- Khởi tạo Terraform workspace

### Bước 3: Kiểm Tra Kế Hoạch (Plan)

```bash
terraform plan -out=tfplan
```

Lệnh này sẽ hiển thị các tài nguyên sẽ được tạo:
- 1 S3 Bucket (với mã hóa và chặn public access)
- 1 SNS Topic cho thông báo
- 1 Email subscription
- 1 Macie classification job
- 1 EventBridge rule
- File dữ liệu mẫu

### Bước 4: Áp Dụng Cấu Hình (Apply)

```bash
terraform apply tfplan
```

Lệnh này sẽ:
- Tạo tất cả tài nguyên trên AWS
- Lưu state file (`terraform.tfstate`)
- Hiển thị các output values

**Quan Trọng**: Sau khi chạy, bạn sẽ nhận được email từ AWS SNS yêu cầu xác nhận subscription.

### Bước 5: Xác Nhận Email Subscription

1. Mở email từ AWS (chủ đề: "AWS Notification - Subscription Confirmation")
2. Nhấp vào link "Confirm subscription"
3. Bạn sẽ thấy thông báo "Subscription confirmed!"

**Lưu ý**: Nếu không nhận được email:
- Kiểm tra thư mục Spam/Junk
- Chờ vài phút và kiểm tra lại
- Có thể xác nhận thủ công từ AWS Console:
  - SNS → Topics → Macie-Alerts-Topic → Subscriptions
  - Tìm subscription của bạn với trạng thái "PendingConfirmation"
  - Nhấp "Confirm subscription"

### Bước 6: Giám Sát Macie Job

1. Đăng nhập AWS Management Console
2. Tìm kiếm dịch vụ "Amazon Macie"
3. Chọn Jobs → Tìm job "S3-Sensitive-Data-Scan-Job"
4. Kiểm tra trạng thái:
   - **Running**: Job đang chạy
   - **Completed**: Job đã hoàn thành
   
Thời gian chạy: 5-30 phút tùy theo kích thước file

### Bước 7: Xem Kết Quả (Findings)

Khi Macie job hoàn thành:

1. Macie Console → Findings
2. Bạn sẽ thấy các phát hiện về dữ liệu nhạy cảm:
   - Credit Card Numbers (Personal/CreditCardNumber)
   - PII (Personally Identifiable Information)
   - API Keys / Credentials
   - Email addresses
   - Phone numbers
   - ID numbers

3. Kiểm tra email - bạn sẽ nhận được SNS notifications với chi tiết findings

## Các File Trong Dự Án

| File | Mô Tả |
|------|-------|
| `providers.tf` | Cấu hình AWS provider |
| `variables.tf` | Khai báo biến đầu vào |
| `s3.tf` | Tạo S3 bucket và upload file mẫu |
| `sns.tf` | Tạo SNS topic và email subscription |
| `macie.tf` | Kích hoạt Macie và tạo classification job |
| `eventbridge.tf` | Tạo rule để chuyển findings đến SNS |
| `outputs.tf` | Hiển thị giá trị output quan trọng |
| `sample_data.txt` | File mẫu chứa dữ liệu giả lập nhạy cảm |
| `terraform.tfvars.example` | File ví dụ biến (copy thành terraform.tfvars) |
| `.gitignore` | Tệp được git bỏ qua |
| `README.md` | Hướng dẫn tiếng Anh |
| `README_VN.md` | Hướng dẫn này |

## Dữ Liệu Mẫu Trong `sample_data.txt`

File này chứa dữ liệu **GIẢ LẬP** để mô phỏng dữ liệu nhạy cảm:

```
Fake Credit Card: 4111 1111 1111 1111
Fake ID: 001012345678
Fake SSN: 123-45-6789
Fake Email: customer@example.com
Fake API Key: AKIA2E9B3F7G8H9I1J2K
```

⚠️ **CẢNH BÁO**: KHÔNG sử dụng dữ liệu thực trong bài lab này!

## Dọn Dẹp Tài Nguyên (Cleanup)

Để xóa tất cả tài nguyên và tránh chi phí:

```bash
terraform destroy
```

Xác nhận bằng cách gõ `yes`

Lệnh này sẽ xóa:
- ✓ S3 bucket và tất cả files
- ✓ SNS topic và subscriptions
- ✓ EventBridge rule
- ✓ Macie job

**Lưu ý**: Macie account có thể vẫn được bật trên AWS. Để hoàn toàn tắt Macie:
1. Macie Console → Settings
2. Chọn "Suspend" hoặc "Disable Macie"

## Xem Output

Để xem các giá trị output đã tạo:

```bash
terraform output
```

Hoặc output cụ thể:

```bash
terraform output s3_bucket_name
terraform output sns_topic_arn
terraform output macie_job_id
```

## Xử Lý Sự Cố

### Vấn đề: Không nhận được email xác nhận
- [ ] Kiểm tra thư mục Spam
- [ ] Xác nhận email trong AWS Console
- [ ] Đợi 5-10 phút và thử lại

### Vấn đề: Macie job không hoàn thành
- [ ] Chờ thêm vài phút
- [ ] Kiểm tra trạng thái job trong AWS Macie Console
- [ ] Kiểm tra CloudWatch Logs

### Vấn đề: Không nhận được findings
- [ ] Xác nhận job đã hoàn thành
- [ ] Kiểm tra email subscription được xác nhận
- [ ] Xem lại Macie console → Findings

### Vấn đề: Terraform apply bị lỗi
```bash
# Kiểm tra credentials
aws sts get-caller-identity

# Xem log chi tiết
export TF_LOG=DEBUG
terraform apply tfplan
```

## Chi Phí Ước Tính

Đây là bài lab nhỏ với chi phí rất thấp:
- **Macie**: ~$0.001 (quét 1000 objects)
- **S3**: Miễn phí (1 file nhỏ)
- **SNS**: Miễn phí (1000 emails/tháng)
- **EventBridge**: Miễn phí (100 rules free)

**Tổng cộng**: Dưới $1 USD

## Lệnh Hữu Ích

```bash
# Khởi tạo
terraform init

# Kiểm tra cấu hình
terraform validate

# Xem kế hoạch
terraform plan

# Áp dụng
terraform apply

# Xem state
terraform show

# Xem output
terraform output

# Xóa tất cả
terraform destroy

# Format lại code
terraform fmt -recursive

# Xóa cache
rm -rf .terraform terraform.tfstate*
```

## Danh Sách Kiểm Tra (Checklist)

- [ ] Chuẩn bị email address
- [ ] Copy terraform.tfvars.example → terraform.tfvars
- [ ] Chỉnh sửa email_address trong terraform.tfvars
- [ ] Chạy terraform init
- [ ] Chạy terraform plan
- [ ] Chạy terraform apply
- [ ] Nhận và xác nhận email SNS subscription
- [ ] Đợi Macie job hoàn thành (5-30 phút)
- [ ] Kiểm tra Findings trong Macie Console
- [ ] Kiểm tra email nhận được thông báo
- [ ] Chạy terraform destroy để dọn dẹp

## Tài Liệu Tham Khảo

- [AWS Macie Docs](https://docs.aws.amazon.com/macie/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS SNS Docs](https://docs.aws.amazon.com/sns/)
- [AWS EventBridge Docs](https://docs.aws.amazon.com/eventbridge/)

## Thời Gian Hoàn Thành

**Tổng cộng**: 45-60 phút
- Chuẩn bị: 5 phút
- Terraform apply: 2-3 phút
- Xác nhận email: 2-5 phút
- Đợi Macie job: 10-30 phút
- Kiểm tra kết quả: 5-10 phút
- Dọn dẹp: 2 phút

## Hỗ Trợ

Nếu gặp vấn đề:
1. Kiểm tra AWS Console status
2. Xem lại README.md (tiếng Anh)
3. Chạy terraform plan để kiểm tra cấu hình
4. Kiểm tra CloudWatch Logs

---

**Ngày cập nhật**: 2026-06-19
**Phiên bản**: 1.0
**AWS Services**: S3, SNS, Macie, EventBridge, IAM
