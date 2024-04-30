## Policy
resource "aws_iam_policy" "policy" {
  name        = "${var.component}-${var.env}- ssm-pm-policy"
  path        = "/"
  description = "${var.component}-${var.env}-ssm-pm-policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource": [
          "arn:aws:ssm:us-east-1:339712793158:parameter/roboshop.dev.${var.env}.*"
        ]
      }
    ]
  })
}

## Iam Role
resource "aws_iam_role" "role" {
  name = "${var.component}-${var.env}- ec2-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource": [
          "arn:aws:ssm:us-east-1:339712793158:parameter/roboshop.dev.${var.env}.*"
        ]
      }
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.component}-${var.env}- ec2-role"
  role = aws_iam_role.role.name
}
## Security group
resource "aws_security_group" "sg" {
  name = "${var.component}-${var.env}-sg"
  description = "${var.component}-${var.env}-sg"
  ingress {
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "-1"
  }
  egress {
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "-1"
  }
  tags = {
    name = "${var.component}-${var.env}-sg"
  }
}
## Ec2

resource "aws_instance" "web" {
  ami           = data.aws_ami.ami.id
  instance_type = "t3.micro"
  vpc_security_group_ids = ["${var.component}-${var.env}-sg"]
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name
  tags = {
    Name = var.component
  }
}
## DNS Record
resource "aws_route53_record" "dns" {
  zone_id = "Z000681610YP12S51X5A5"
  name    = "${var.component}-dev"
  type    = "A"
  ttl     = 30
  records = [aws_instance.web.private_ip]
}

## Null Resource - Ansible
resource "null_resource" "ansible" {
  depends_on = [aws_instance.web, aws_route53_record.dns]

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "centos"
      password = "DevOps 321"
      host     = aws_instance.web.public_ip
    }

    inline = [
      "sudo labauto ansible",
      "ansible-pull -i localhost, -U https://github.com/sandeepreddymunagala/roboshop-ansible main.yml -e env=${var.env} -e role_name=${var.component}"
    ]
  }
}
