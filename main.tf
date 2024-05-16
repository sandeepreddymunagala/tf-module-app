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

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = var.allow_prometheus_cidr
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allow_ssh_cidr
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
## Ec2
resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  tags = merge({
    Name = "${var.component}-${var.env}"
  },var.tags)
}

## DNS record
resource "aws_route53_record" "dns" {
  name    = "${var.component}-${var.env}.sandeepreddymunagala123.xyz"
  type    = "A"
  zone_id = "Z000681610YP12S51X5A5"
  ttl     = 300  # Example TTL value (in seconds)

  records = [
    aws_instance.instance.private_ip
  ]
}





