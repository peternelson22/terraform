terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.31.0"
    }
  }
}
provider "aws" {
  region = "us-east-1"
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

resource "aws_launch_configuration" "example" {
  image_id = "ami-079db87dc4c10ac91"

  instance_type   = "t2.micro"
  security_groups = [aws_security_group.sgserver.id]
  user_data       = <<-EOF
                    #!/bin/bash
                    echo "Hello, World" > index.xhtml
                    nohup busybox httpd -f -p ${var.port} &
                    EOF
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = data.aws_subnets.default.ids
  target_group_arns    = [aws_lb_target_group.example.arn]
  health_check_type    = "ELB"

  max_size = 10
  min_size = 2

  tag {
    key                 = "Name"
    value               = "Terraform-Example"
    propagate_at_launch = true
  }

}

resource "aws_lb" "example" {
  name               = "terraform-example"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
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
  name     = "terraform-lb-target"
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

resource "aws_security_group" "sgserver" {
  name = "my-sgserver"
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "Incoming traffic"
      from_port        = var.port
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = var.port
    }
  ]
}

resource "aws_security_group" "alb" {
  name = "alb-sg"
  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "inbound rule"
      from_port        = 80
      prefix_list_ids  = []
      ipv6_cidr_blocks = []
      protocol         = "tcp"
      security_groups  = []
      self             = false
      to_port          = 80
    }
  ]
  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "outbound rule"
      from_port        = 0
      prefix_list_ids  = []
      ipv6_cidr_blocks = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
}

