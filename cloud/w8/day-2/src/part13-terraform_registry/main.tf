# module "registry_bucket" {
#   source  = "terraform-aws-modules/s3-bucket/aws"
#   version = "~> 5.0"

#   bucket_prefix = "tf-series-bai13-reg-"
#   force_destroy = true
# }

module "registry_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  # Pin to the newest available v5 release from the Terraform Registry.
  version = "5.14.0"

  bucket_prefix = "tf-series-bai13-reg-"
  force_destroy = true
}
