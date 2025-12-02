output "private_app_ip" {
  description = "Private IP of the Ubuntu App Instance"
  value       = aws_instance.private_app.private_ip
}

output "private_key_path" {
  description = "Path to the generated SSH Private Key"
  value       = local_file.put_key_on_local_file.filename
}

data "aws_instances" "nat_instances" {
  instance_tags = {
    Name = "fck-nat-instance"
  }

  instance_state_names = ["running"]
  depends_on           = [aws_autoscaling_group.fck_nat_asg]
}

output "nat_public_ips" {
  description = "List of Public IPs for instances in the Auto Scaling Group"
  value       = data.aws_instances.nat_instances.public_ips
}
output "route_table_id" {
  description = "Route Table ID for the private subnet"
  value       = aws_route_table.private.id
}
