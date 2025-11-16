locals {
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  services = {
    product = {
      name       = "product-service"
      port       = 8000
      path_match = "/products/*"
      priority   = 10
    }
    order = {
      name       = "order-service"
      port       = 8001
      path_match = "/orders/*"
      priority   = 20
    }
    frontend = {
      name       = "frontend"
      port       = 3000
      path_match = "/*"
      priority   = 30
    }
  }
}

resource "aws_ecs_cluster" "this" {
  name = "${var.project_name}-${var.environment}-cluster"
  tags = merge(local.tags, { Name = "${var.project_name}-${var.environment}-cluster" })
}

resource "aws_lb" "this" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
  tags               = merge(local.tags, { Name = "${var.project_name}-${var.environment}-alb" })
}

resource "aws_lb_target_group" "services" {
  for_each = local.services

  name        = "${var.project_name}-${var.environment}-${each.value.name}"
  port        = each.value.port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    matcher             = "200-399"
  }

  tags = merge(local.tags, { Service = each.value.name })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services["frontend"].arn
  }
}

resource "aws_lb_listener_rule" "routing" {
  for_each = {
    for key, svc in local.services : key => svc if key != "frontend"
  }

  listener_arn = aws_lb_listener.http.arn
  priority     = each.value.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.services[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_match]
    }
  }
}
