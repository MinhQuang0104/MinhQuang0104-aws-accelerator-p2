variable "aws_region" {
  description = "AWS region used by this lab."
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Name prefix for resources created by this lab."
  type        = string
  default     = "cloudwatch-agent-lab"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Optional name of an existing EC2 key pair for SSH access."
  type        = string
  default     = null
  nullable    = true
}

variable "ssh_allowed_cidr" {
  description = "Optional trusted CIDR for SSH, for example 203.0.113.10/32. Leave null to keep port 22 closed and use Session Manager."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.ssh_allowed_cidr == null || can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be null or a valid CIDR block."
  }
}
