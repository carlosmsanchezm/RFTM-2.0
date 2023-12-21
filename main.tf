terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MainVPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "MainInternetGateway"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "PrivateSubnet1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "PrivateSubnet2"
  }
}


resource "aws_eip" "nat_eip" {
  domain = "vpc"
}


resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "MainNATGateway"
  }
}


resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}


resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "PrivateRouteTable"
  }
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}


# Example IAM role and policy for EC2
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "cloudwatch:*",
          "s3:*",
          # Other necessary permissions
        ],
        Effect   = "Allow",
        Resource = "*"
      },
    ]
  })
}


# Attach IAM role to EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_elb" "example" {
  name      = "example-elb"
  instances = [aws_instance.example["dvwa"].id]
  subnets   = [aws_subnet.public_subnet.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = aws_iam_server_certificate.self_signed_cert.arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400


  tags = {
    Name = "example-elb"
  }
}

resource "aws_iam_server_certificate" "self_signed_cert" {
  name             = "self-signed-cert"
  certificate_body = file("${path.module}/mycert.crt")
  private_key      = file("${path.module}/mykey.key")
}

variable "instances" {
  default = {
    "dvwa"  = "t2.micro"
    "mysql" = "t2.micro"
  }
}

data "aws_ami" "example" {
  most_recent = true
  owners      = ["amazon"] # 'amazon' for Amazon-owned AMIs

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"] # Filter for Amazon Linux 2 AMIs
  }

  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "common_key" {
  key_name   = "common-key"
  public_key = file("~/.ssh/id_rsa.pub") # Path to your public key file
}

resource "aws_instance" "example" {
  for_each             = var.instances
  ami                  = data.aws_ami.example.id
  instance_type        = each.value
  key_name             = aws_key_pair.common_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Attach to respective private subnets
  subnet_id = each.key == "dvwa" ? aws_subnet.private_subnet_1.id : aws_subnet.private_subnet_2.id

  # Ensure that the instances are not assigned public IPs
  associate_public_ip_address = false

  # Use the correct security group for each instance
  vpc_security_group_ids = [each.key == "dvwa" ? aws_security_group.dvwa_sg.id : aws_security_group.mysql_sg.id]

  tags = {
    Name = "Instance-${each.key}"
    Type = each.key  # Include the Type tag
  }
}

variable "bastion_instance_type" {
  default = "t2.micro"
}

resource "aws_instance" "bastion_host" {
  ami           = data.aws_ami.example.id
  instance_type = var.bastion_instance_type
  key_name      = aws_key_pair.common_key.key_name
  subnet_id     = aws_subnet.public_subnet.id  # Place in the public subnet

  associate_public_ip_address = true  # Assign a public IP

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "BastionHost"
  }
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-security-group"
  description = "Security Group for Bastion Host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #["${var.student_public_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}




resource "aws_security_group" "dvwa_sg" {
  name        = "dvwa-security-group"
  description = "Security Group for DVWA Instance"
  vpc_id      = aws_vpc.main.id

  # SSH Access (Restrict to known IPs)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP and HTTPS Access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dvwa-sg"
  }
}

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-security-group"
  description = "Security Group for MySQL Instance"
  vpc_id      = aws_vpc.main.id

  # MySQL Access from DVWA Instance
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.dvwa_sg.id]
  }

  # Outbound Rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql-sg"
  }
}

resource "aws_sns_topic" "alarm_topic" {
  name = "alarm-topic"
}

resource "aws_sns_topic_subscription" "alarm_subscription" {
  topic_arn = aws_sns_topic.alarm_topic.arn
  protocol  = "email"
  endpoint  = "example@example.com" # Replace with your email
}


resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "HighCPUAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_actions       = [aws_sns_topic.alarm_topic.arn]

  dimensions = {
    InstanceId = aws_instance.example["dvwa"].id
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    bastion_host_public_ip = aws_instance.bastion_host.public_ip,
    dvwa_public_ips        = [for instance in aws_instance.example : instance.public_ip if instance.tags["Type"] == "dvwa"],
    mysql_private_ips      = [for instance in aws_instance.example : instance.private_ip if instance.tags["Type"] == "mysql"]
  })
  filename = "${path.module}/inventory.ini"
}
