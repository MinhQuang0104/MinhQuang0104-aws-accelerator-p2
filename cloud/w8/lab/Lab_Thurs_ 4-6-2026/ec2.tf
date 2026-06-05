locals {
  ssh_public_key = var.public_key_content != null ? trimspace(var.public_key_content) : trimspace(file(var.public_key_path))
}

data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_key_pair" "main" {
  key_name_prefix = "${var.project_name}-"
  public_key      = local.ssh_public_key

  lifecycle {
    precondition {
      condition     = var.public_key_content != null || var.public_key_path != null
      error_message = "Set either public_key_content or public_key_path."
    }
  }

  tags = {
    Name = "${var.project_name}-key"
  }
}

resource "aws_instance" "minikube" {
  ami                         = data.aws_ami.ubuntu_2404.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.main.key_name
  vpc_security_group_ids      = [aws_security_group.ec2.id]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
  }

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    node_port = var.node_port
  })

  depends_on = [
    aws_route_table_association.public
  ]

  tags = {
    Name = "${var.project_name}-minikube"
  }
}

# Wait for cloud-init to mark Minikube ready before deploying the application.
resource "null_resource" "minikube_ready" {
  triggers = {
    instance_id = aws_instance.minikube.id
    public_ip   = aws_instance.minikube.public_ip
    node_port   = tostring(var.node_port)
    user_data   = sha256(aws_instance.minikube.user_data)
  }

  connection {
    type        = "ssh"
    host        = aws_instance.minikube.public_ip
    user        = "ubuntu"
    private_key = file(var.private_key_path)
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "for i in $(seq 1 120); do test -f /tmp/minikube-ready && break; echo 'Waiting for Minikube...'; sleep 10; done; test -f /tmp/minikube-ready || { echo 'Minikube did not become ready' >&2; exit 1; }"
    ]
  }
}
