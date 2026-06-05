resource "aws_lb" "main" {
  name               = substr("${var.project_name}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "nginx" {
  name        = substr("${var.project_name}-tg", 0, 32)
  port        = var.node_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
    timeout             = 5
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

resource "aws_lb_target_group_attachment" "minikube" {
  target_group_arn = aws_lb_target_group.nginx.arn
  target_id        = aws_instance.minikube.id
  port             = var.node_port

  # Register the target only after kubectl has created the NodePort service.
  depends_on = [
    null_resource.deploy_nginx
  ]
}
