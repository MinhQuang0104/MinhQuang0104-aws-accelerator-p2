resource "aws_s3_bucket" "first" {
  bucket_prefix = "tf-series-bai2-"
  force_destroy = true

  tags = {
    Project = "terraform-series"
    Bai     = "02"
  }
}

output "bucket_name" {
  value = aws_s3_bucket.first.id
}

output "bucket_arn" {
  value = aws_s3_bucket.first.arn
}

resource "aws_s3_bucket" "second" {
  bucket_prefix = "tf-series-test-s3-"
  force_destroy = true

  tags = {
    Project = "terraform-series"
    Bai     = "02"
  }
}

