locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

resource "aws_launch_configuration" "example" {
  image_id = var.ami

  instance_type   = var.instance_type
  security_groups = [aws_security_group.sgserver.id]
  user_data       = var.user_data
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_group" "example" {
  name                 = var.cluster_name
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier  = var.subnet_ids
  target_group_arns    = var.target_group_arns
  health_check_type    = var.health_check_type

  max_size = var.max_size
  min_size = var.min_size

  # Use instance refresh to roll out changes to the ASG
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
  dynamic "tag" {
    for_each = {
      for key, value in var.custom_tags : key => upper(value) if key != "Name"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
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