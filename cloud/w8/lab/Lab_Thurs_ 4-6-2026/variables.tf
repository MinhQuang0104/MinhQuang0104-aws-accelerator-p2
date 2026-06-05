variable "aws_region" {
  description = "AWS region in which to create the lab."
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "EC2 instance type for the Minikube host."
  type        = string
  default     = "t3.medium"
}

variable "my_ip_cidr" {
  description = "Your public IP address in CIDR notation, used for SSH access."
  type        = string

  validation {
    condition     = can(cidrhost(var.my_ip_cidr, 0))
    error_message = "my_ip_cidr must be a valid CIDR, for example 203.0.113.10/32."
  }
}

variable "public_key_path" {
  description = "Path to an existing SSH public key. Used when public_key_content is null."
  type        = string
  default     = null
  nullable    = true
}

variable "public_key_content" {
  description = "SSH public key content. Takes precedence over public_key_path."
  type        = string
  default     = null
  nullable    = true
}

variable "private_key_path" {
  description = "Path to the unencrypted private SSH key matching the supplied public key. Required by non-interactive remote-exec."
  type        = string
}

variable "node_port" {
  description = "Kubernetes NodePort exposed on the EC2 host and used by the ALB target group."
  type        = number
  default     = 30080

  validation {
    condition     = var.node_port >= 30000 && var.node_port <= 32767
    error_message = "node_port must be within the Kubernetes NodePort range 30000-32767."
  }
}

variable "project_name" {
  description = "Name prefix used for AWS resources."
  type        = string
  default     = "k8s-minikube-lab"
}
