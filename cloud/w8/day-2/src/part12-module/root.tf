module "logs" {
  source        = "./modules/secure-bucket"
  name_prefix   = "tf-series-bai12-logs-"
  force_destroy = true
  tags          = { Purpose = "logs" }
}

module "data" {
  source        = "./modules/secure-bucket"
  name_prefix   = "tf-series-bai12-data-"
  versioning    = false
  force_destroy = true
  tags          = { Purpose = "data" }
}

output "logs_bucket" {
  value = module.logs.id
}

output "data_bucket_arn" {
  value = module.data.arn
}
