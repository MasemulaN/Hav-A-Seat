output "aws_region" {
  description = "AWS region used for the Hav-A-Seat infrastructure"
  value       = var.aws_region
}

output "vpc_id" {
  description = "ID of the Hav-A-Seat VPC"
  value       = aws_vpc.hav_a_seat.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.hav_a_seat.id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.hav_a_seat.dns_name
}

output "rds_endpoint" {
  description = "Endpoint of the PostgreSQL RDS instance"
  value       = aws_db_instance.hav_a_seat.address
}

output "rds_port" {
  description = "Port used by the PostgreSQL RDS instance"
  value       = aws_db_instance.hav_a_seat.port
}

output "autoscaling_group_name" {
  description = "Name of the Hav-A-Seat Auto Scaling Group"
  value       = aws_autoscaling_group.hav_a_seat.name
}