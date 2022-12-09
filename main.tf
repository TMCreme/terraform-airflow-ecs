terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.default_region
}

# Create a VPC
resource "aws_vpc" "airflow_vpc" {
  cidr_block = var.eu_west_cidr_block
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.airflow_vpc.id

  tags = {
    Name = var.internet_gateway_name
  }
}

# Route table to internet gateway
resource "aws_default_route_table" "airflow_tb_test" {
  default_route_table_id = aws_vpc.airflow_vpc.default_route_table_id
  #   vpc_id = aws_vpc.airflow_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = var.route_table_rule
  }
}

# Create 2 subnets in different AZs, one each
# first subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.airflow_vpc.id
  cidr_block        = var.first_subnet_cidr
  availability_zone = var.first_subnet_az

  tags = {
    Name = var.first_subnet_name
  }
}

# Second Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.airflow_vpc.id
  cidr_block        = var.second_subnet_cidr
  availability_zone = var.second_subnet_az

  tags = {
    Name = var.second_subnet_name
  }
}

# Create a Security Group 
resource "aws_security_group" "alb_to_internet_comm_allow" {
  name        = var.security_group_to_internet_name
  description = "Allow Internet traffic connections to Load balancer"
  vpc_id      = aws_vpc.airflow_vpc.id

  ingress {
    description      = "Allow Connection to http"
    from_port        = var.internet_sg_from_port
    to_port          = var.internet_sg_to_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = var.security_group_to_internet_name
  }
}

# Create another Security Group to allow traffic from 
# the internet facing sg to ecs 
resource "aws_security_group" "alb_to_ecs_traffic" {
  name        = var.security_group_to_ecs_name
  description = "Allow SG connections"
  vpc_id      = aws_vpc.airflow_vpc.id

  ingress {
    description     = "Allow Connection from SG to ECS"
    from_port       = var.ecs_to_lb_sg_from_port
    to_port         = var.ecs_to_lb_sg_to_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_to_internet_comm_allow.id]
    # ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = var.security_group_to_ecs_name
  }
}

# Create an application load balancer 
resource "aws_lb" "alb_ecs_airflow" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_to_internet_comm_allow.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_subnet.id]

  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "test"
  }
}

# Create a target group for the load balancer
resource "aws_lb_target_group" "alb_ecs_airflow_tg" {
  name        = var.target_group_name
  target_type = "ip"
  port        = var.target_group_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.airflow_vpc.id
}

# Create a listener for the Load balancer
resource "aws_lb_listener" "alb_ecs_airflow" {
  load_balancer_arn = aws_lb.alb_ecs_airflow.arn
  port              = var.listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_ecs_airflow_tg.arn
  }

  #   default_action {
  #     type = "fixed-response"

  #     fixed_response {
  #       content_type = "text/plain"
  #       message_body = "Fixed response content"
  #       status_code  = "200"
  #     }
  #   }

}

# CloudWatch 
resource "aws_cloudwatch_log_group" "log" {
  name              = var.cloudwatch_ecs_log_name
  retention_in_days = var.cloudwatch_log_retention_days
}

# ECS Cluster creation
resource "aws_ecs_cluster" "test_airflow" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.log.name
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "test_airflowcp" {
  cluster_name = aws_ecs_cluster.test_airflow.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}


resource "aws_ecs_task_definition" "airflowtestfamily" {
  family                   = var.ecs_task_definition_family_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.ecs_container_cpu
  memory                   = var.ecs_container_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  container_definitions = jsonencode([
    {
      name      = var.ecs_task_container_name
      image     = var.ecs_container_image
      cpu       = var.ecs_container_cpu
      memory    = var.ecs_container_memory
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

}


resource "aws_ecs_service" "airflowtestservice" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.test_airflow.id
  task_definition = "${aws_ecs_task_definition.airflowtestfamily.family}:${aws_ecs_task_definition.airflowtestfamily.revision}"
  desired_count   = 1
  launch_type = var.ecs_service_launch_type

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_ecs_airflow_tg.arn
    container_name   = var.ecs_task_container_name
    container_port   = 80
  }

  network_configuration {
    subnets         = [aws_subnet.public.id, aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.alb_to_ecs_traffic.id]
    assign_public_ip = true
  }
}


