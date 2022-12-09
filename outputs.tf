output "security_group" {
  description = "ID of the Security Group"
  value       = aws_security_group.alb_to_internet_comm_allow.id
}

output "vpc_id" {
  description = "Public IP address of the EC2 instance"
  value       = aws_vpc.airflow_vpc.id
}

output "subnet_id" {
    description = "Subnet IDs"
    value = aws_subnet.public.id
}

output "loadbalancer_arn" {
    description = "Load balancer LINk"
    value = aws_lb.alb_ecs_airflow.dns_name
}



#   ingress {
#     description      = "Allow Connection to Postgres"
#     from_port        = 5432
#     to_port          = 5432
#     protocol         = "tcp"
#     cidr_blocks      = [aws_vpc.airflow_vpc.cidr_block]
#     ipv6_cidr_blocks = ["::/0"]
#   }
