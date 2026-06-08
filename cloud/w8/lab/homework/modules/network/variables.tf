variable "name" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = map(string)
  description = "Map: AZ -> public subnet CIDR"
}

variable "private_subnets" {
  type        = map(string)
  description = "Map: AZ -> private subnet CIDR"
}
