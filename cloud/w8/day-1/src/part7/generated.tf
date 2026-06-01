# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "tf-part7-before"
resource "aws_s3_bucket" "adopted" {
  bucket              = "tf-part7-before"
  force_destroy       = null
  object_lock_enabled = false
  tags                = {}
  tags_all            = {}
}
