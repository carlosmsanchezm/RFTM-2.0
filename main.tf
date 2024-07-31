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
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          # Add any other necessary CloudWatch Logs actions
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
  security_groups = [aws_security_group.elb_sg.id]

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
    target              = "HTTP:80/login.php"
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

  # filter {
  #   name   = "name"
  #   values = ["amzn2-ami-hvm-*-x86_64-gp2"] # Filter for Amazon Linux 2 AMIs
  # }

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
  ami                  = "ami-079db87dc4c10ac91"
  instance_type        = each.value
  key_name             = aws_key_pair.common_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  # Attach DVWA to public subnet and MySQL to private subnet
  subnet_id = each.key == "dvwa" ? aws_subnet.public_subnet.id : aws_subnet.private_subnet_2.id

  # Assign public IP for DVWA instance and not for MySQL
  associate_public_ip_address = each.key == "dvwa" ? true : false

  # Use the correct security group for each instance
  vpc_security_group_ids = [each.key == "dvwa" ? aws_security_group.dvwa_sg.id : aws_security_group.mysql_sg.id]

  tags = {
    Name = "Instance-${each.key}"
    Type = each.key
  }
}

variable "bastion_instance_type" {
  default = "t2.micro"
}

resource "aws_instance" "bastion_host" {
  ami           = "ami-079db87dc4c10ac91"
  instance_type = var.bastion_instance_type
  key_name      = aws_key_pair.common_key.key_name
  subnet_id     = aws_subnet.public_subnet.id  # Place in the public subnet

  associate_public_ip_address = true  # Assign a public IP

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "BastionHost"
  }
}

resource "aws_security_group" "elb_sg" {
  name        = "elb-security-group"
  description = "Security group for ELB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80  # HTTP
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443  # HTTPS
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "elb-sg"
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

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
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

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tmpl", {
    bastion_host_public_ip = aws_instance.bastion_host.public_ip,
    dvwa_public_ips        = [for instance in aws_instance.example : instance.public_ip if instance.tags["Type"] == "dvwa"],
    mysql_private_ips      = [for instance in aws_instance.example : instance.private_ip if instance.tags["Type"] == "mysql"]
  })
  filename = "${path.module}/inventory.ini"
}

resource "aws_cloudwatch_metric_alarm" "sql_injection_alarm" {
  alarm_name                = "DVWASQLInjectionAlarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "SQLInjectionEvents"
  namespace                 = "DVWA/Security"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "Alarm when SQL Injection detected"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.security_alerts.arn]
}

resource "aws_cloudwatch_log_group" "dvwa_logs" {
  name = "dvwa-logs"
}

resource "aws_cloudwatch_log_metric_filter" "sql_injection_filter" {
  name           = "SQLInjectionFilter"
  log_group_name = aws_cloudwatch_log_group.dvwa_logs.name
  pattern        = "\"%27+OR+%271%27%3D%271\""

  metric_transformation {
    name      = "SQLInjectionEvents"
    namespace = "DVWA/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "xss_filter" {
  name           = "XSSFilter"
  pattern        = "\"%3Cscript%3Ealert%28%27XSS%27%29%3B%3C%2Fscript%3E\""
  log_group_name = aws_cloudwatch_log_group.dvwa_logs.name
  metric_transformation {
    name      = "XSSAttackEvents"
    namespace = "DVWA/Security"
    value     = "1"
  }
}


resource "aws_cloudwatch_metric_alarm" "xss_alarm" {
  alarm_name                = "DVWAXSSAlarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "XSSAttackEvents"
  namespace                 = "DVWA/Security"
  period                    = "300"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "Alarm when XSS attack detected"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.security_alerts.arn]
}

resource "aws_cloudwatch_log_metric_filter" "brute_force_filter" {
  name           = "BruteForceFilter"
  pattern        = "\"POST /login.php/login.php\" 302"
  log_group_name = aws_cloudwatch_log_group.dvwa_logs.name
  metric_transformation {
    name      = "FailedLoginAttempts"
    namespace = "DVWA/Security"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "brute_force_alarm" {
  alarm_name                = "DVWABruteForceAlarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  metric_name               = "FailedLoginAttempts"
  namespace                 = "DVWA/Security"
  period                    = "300" # 5 minutes
  statistic                 = "Sum"
  threshold                 = "50" # Threshold for failed attempts within 5 minutes
  alarm_description         = "Alarm when high frequency of failed logins detected"
  insufficient_data_actions = []
  alarm_actions             = [aws_sns_topic.security_alerts.arn]
}

resource "aws_sns_topic" "security_alerts" {
  name = "security-alerts"
}

resource "aws_sns_topic_subscription" "security_alerts_subscription" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = "cms553@cornell.edu"
}
