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

module "asg" {
  source = "../../cluster/asg-rolling-deploy"

  cluster_name  = "hello-world-${var.environment}"
  ami           = var.ami
  instance_type = var.instance_type
  user_data = templatefile("${path.module}/user-data.sh", {
  server_port = var.port })
  min_size           = var.min_size
  max_size           = var.max_size
  enable_autoscaling = var.enable_autoscaling
  subnet_ids         = data.aws_subnets.default.ids
  target_group_arns  = [aws_lb_target_group.asg.arn]
  health_check_type  = "ELB"
  custom_tags        = var.custom_tags
}
module "alb" {
  source     = "../../networking/alb"
  alb_name   = "hello-world-${var.environment}"
  subnet_ids = data.aws_subnets.default.ids
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

resource "aws_lb_target_group" "example" {
  name     = "${var.environment}-lb-target"
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
  listener_arn = module.alb.alb_http_listener_arn
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
