terraform {
  # backend "s3" {
  #   bucket = "tfstate-locks-23672378t58237tr8"
  #   key    = "stage/services/webservercluster/terraform.tfstate"
  #   region = "us-east-1"

  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true

  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
  }
}

data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

resource "aws_launch_configuration" "example" {
  image_id = "ami-079db87dc4c10ac91"

  instance_type   = var.instance_type
  security_groups = [aws_security_group.sgserver.id]
  user_data       = templatefile("${path.module}/user-data.sh", { server_port = var.port })
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns    = [aws_lb_target_group.example.arn]
  health_check_type    = "ELB"

  max_size = var.max_size
  min_size = var.min_size


  dynamic "tag" {
    for_each = var.custom_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_lb" "example" {
  name               = "${var.cluster_name}-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Not found"
      status_code  = 404
    }
  }

}

resource "aws_lb_target_group" "example" {
  name     = "${var.cluster_name}-lb-target"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "example" {
  listener_arn = aws_lb_listener.example.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }

}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count                  = var.enable_autoscaling ? 1 : 0
  scheduled_action_name  = "${var.cluster_name}-scale_out_during_business_hours"
  min_size               = 2
  max_size               = 5
  desired_capacity       = 5
  recurrence             = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count                  = var.enable_autoscaling ? 1 : 0
  scheduled_action_name  = "${var.cluster_name}-scale-in-at-night"
  min_size               = 2
  max_size               = 5
  desired_capacity       = 2
  recurrence             = "0 17 * * *"
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_security_group" "sgserver" {
  name = "${var.cluster_name}-sg"
  ingress = [
    {
      cidr_blocks      = local.all_ips
      description      = "Incoming traffic"
      from_port        = var.port
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = local.tcp_protocol
      security_groups  = []
      self             = false
      to_port          = var.port
    }
  ]
}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb-sg"

}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = local.all_ips
  from_port         = local.http_port
  protocol          = local.tcp_protocol
  to_port           = local.http_port
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = local.all_ips
  from_port         = local.any_port
  protocol          = local.any_protocol
  to_port           = local.any_port
}