variable "name_prefix" {
  type        = string
  description = "Tiền tố tên bucket"
}

variable "versioning" {
  type    = bool
  default = true
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}