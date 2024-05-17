## policy

## security group
resource "aws_security_group" "main" {
  name        = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = var.sg_subnets_cidr
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}-${var.env}-sg"
  }
}

resource "aws_launch_template" "main" {
  name = "${var.component}-${var.env}"

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }
  image_id               = data.aws_ami.ami.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]

  tag_specifications {
    resource_type = "instance"
    tags          = merge({ Name = "${var.component}-${var.env}", Monitor = "true" }, var.tags)
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    env       = var.env
    component = var.component
  }))

/*  block_device_mappings {
  device_name = "/dev/sda1"
  ebs {
  volume_size = 10
  encrypted   = "true"
  kms_key_id  = var.kms_key_id
  }
 }*/
}

resource "aws_lb_target_group" "main" {
  name                 = "${var.component}-${var.env}-tg"
  port                 = var.app_port
  protocol             = "HTTP"
  deregistration_delay = 30
  vpc_id               = var.vpc_id

  health_check {
    enabled             = true
    interval            = 5
    path                = "/health"
    port                = var.app_port
    protocol            = "HTTP"
    timeout             = 4
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "static" {
  listener_arn = var.listener_arn
  priority     = var.lb_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }

  condition {
    host_header {
      values = ["${local.dns_name}.sandeepreddymunagala123.xyz"]
    }
  }
}
## Ec2
resource "aws_autoscaling_group" "main" {
  desired_capacity = var.desired_capacity
  max_size = var.max_size
  min_size = var.min_size
  vpc_zone_identifier = var.subnets
  target_group_arns   = [aws_lb_target_group.main.arn]
  launch_template {
    id = aws_launch_template.main.id
    version = "$Latest"
  }
}

## DNS record
resource "aws_route53_record" "dns" {
  name    = "${var.component}-${var.env}.sandeepreddymunagala123.xyz"
  type    = "CNAME"
  zone_id = "Z000681610YP12S51X5A5"
  ttl     = 300  # Example TTL value (in seconds)

  records = [var.lb_dns_name  ]
}





