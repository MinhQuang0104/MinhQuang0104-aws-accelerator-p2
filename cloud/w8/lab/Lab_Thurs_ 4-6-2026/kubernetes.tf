# Deploy nginx with kubectl on the EC2 host after Minikube is ready. This avoids
# the Kubernetes Provider lifecycle limitation and supports one apply from an
# empty Terraform state.
resource "null_resource" "deploy_nginx" {
  triggers = {
    instance_id      = aws_instance.minikube.id
    public_ip        = aws_instance.minikube.public_ip
    private_key_path = var.private_key_path
    manifest_sha256 = sha256(templatefile("${path.module}/nginx.yaml.tftpl", {
      node_port = var.node_port
    }))
  }

  connection {
    type        = "ssh"
    host        = self.triggers.public_ip
    user        = "ubuntu"
    private_key = file(self.triggers.private_key_path)
    timeout     = "10m"
  }

  provisioner "file" {
    content = templatefile("${path.module}/nginx.yaml.tftpl", {
      node_port = var.node_port
    })
    destination = "/tmp/nginx.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl apply -f /tmp/nginx.yaml",
      "kubectl -n nginx rollout status deployment/nginx --timeout=5m",
      "kubectl -n nginx get service nginx"
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    inline = [
      "kubectl delete -f /tmp/nginx.yaml --ignore-not-found=true || true"
    ]
  }

  depends_on = [
    null_resource.minikube_ready
  ]
}
