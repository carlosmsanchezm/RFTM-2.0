output "bastion_host_public_ip" {
  value = aws_instance.bastion_host.public_ip
}

output "dvwa_instance_ips" {
  value = [for instance in aws_instance.example : instance.public_ip if instance.tags["Type"] == "dvwa"]
}

output "mysql_instance_private_ips" {
  value = [for instance in aws_instance.example : instance.private_ip if instance.tags["Type"] == "mysql"]
}


