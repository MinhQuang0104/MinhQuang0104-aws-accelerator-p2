data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "The database password must be at least 8 characters."
  }
}

module "network" {
  source   = "./modules/network"
  name     = "tf-series-bai14"
  vpc_cidr = "10.0.0.0/16"

  public_subnets = {
    (data.aws_availability_zones.available.names[0]) = cidrsubnet("10.0.0.0/16", 8, 0)
    (data.aws_availability_zones.available.names[1]) = cidrsubnet("10.0.0.0/16", 8, 1)
  }

  private_subnets = {
    (data.aws_availability_zones.available.names[0]) = cidrsubnet("10.0.0.0/16", 8, 10)
    (data.aws_availability_zones.available.names[1]) = cidrsubnet("10.0.0.0/16", 8, 11)
  }
}

resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Allow HTTP inbound traffic to web server"
  vpc_id      = module.network.vpc_id

  ingress {
    description = "HTTP from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-series-bai14-web-sg"
  }
}

resource "aws_security_group" "db" {
  name        = "db-sg"
  description = "Allow MySQL traffic from web server only"
  vpc_id      = module.network.vpc_id

  ingress {
    description     = "MySQL from web security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-series-bai14-db-sg"
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t3.micro"
  subnet_id              = module.network.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "Hello from Terraform web server" > /usr/share/nginx/html/index.html
  EOF

  tags = {
    Name = "tf-series-bai14-web"
  }
}

resource "aws_db_subnet_group" "private" {
  name       = "tf-series-bai14-db-subnet-group"
  subnet_ids = module.network.private_subnet_ids

  tags = {
    Name = "tf-series-bai14-db-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  db_name                = "appdb"
  db_subnet_group_name   = aws_db_subnet_group.private.name
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  password               = var.db_password
  publicly_accessible    = false
  skip_final_snapshot    = true
  username               = var.db_username
  vpc_security_group_ids = [aws_security_group.db.id]

  tags = {
    Name = "tf-series-bai14-mysql"
  }
}

resource "aws_s3_bucket" "static_assets" {
  bucket_prefix = "tf-series-bai14-static-assets-"

  tags = {
    Name = "tf-series-bai14-static-assets"
  }
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  bucket = aws_s3_bucket.static_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
