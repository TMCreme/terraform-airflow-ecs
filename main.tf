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
  region = "eu-west-1"
}

# Create a VPC
resource "aws_vpc" "airflow_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.airflow_vpc.id

  tags = {
    Name = "airflow-deploy-test"
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
    Name = "airflow_test_rt"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.airflow_vpc.id
  cidr_block        = "10.0.0.0/20"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "Test_Subnet1"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.airflow_vpc.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "Test_Subnet2"
  }
}

# Create a Security Group 
resource "aws_security_group" "alb_to_internet_comm_allow" {
  name        = "alb_to_internet_comm_allow"
  description = "Allow Airflow connections"
  vpc_id      = aws_vpc.airflow_vpc.id

  ingress {
    description      = "Allow Connection to http"
    from_port        = 80
    to_port          = 80
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
    Name = "internet_traffic_to"
  }
}

# Create another Security Group to allow traffic from 
# the internet facing sg to ecs 
resource "aws_security_group" "alb_to_ecs_traffic" {
  name        = "alb_to_ecs_traffic"
  description = "Allow SG connections"
  vpc_id      = aws_vpc.airflow_vpc.id

  ingress {
    description     = "Allow Connection from SG to ECS"
    from_port       = 80
    to_port         = 80
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
    Name = "alb_to_traffic"
  }
}

# Create an application load balancer 
resource "aws_lb" "alb_ecs_airflow" {
  name               = "alb-ecs-airflow"
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
    Environment = "airflowtest"
  }
}

resource "aws_lb_target_group" "alb_ecs_airflow_tg" {
  name        = "alb-ecs-airflow-tg"
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.airflow_vpc.id
}

resource "aws_lb_listener" "alb_ecs_airflow" {
  load_balancer_arn = aws_lb.alb_ecs_airflow.arn
  port              = "80"
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


resource "aws_ecs_cluster" "test_airflow" {
  name = "test_airflow"
}

resource "aws_ecs_cluster_capacity_providers" "test_airflowcp" {
  cluster_name = aws_ecs_cluster.test_airflow.name

  capacity_providers = ["FARGATE"]
}

resource "aws_cloudwatch_log_group" "log" {
  name              = "ecs/nginx"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "nginxtestfamily" {
  family                   = "nginxtestfamily"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name      = "nginxtest"
      image     = "nginx:latest"
      cpu       = 1024
      memory    = 2048
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


resource "aws_ecs_service" "nginxtestservice" {
  name            = "nginxtestservice"
  cluster         = aws_ecs_cluster.test_airflow.id
  task_definition = "${aws_ecs_task_definition.nginxtestfamily.family}:${aws_ecs_task_definition.nginxtestfamily.revision}"
  desired_count   = 2
  #   iam_role        = "arn:aws:iam::291509689978:role/ecsTaskExecutionRole"
  #   depends_on      = [aws_iam_role_policy.foo]
#   "${aws_ecs_task_definition.my_task.family}:${aws_ecs_task_definition.my_task.revision}"
  launch_type = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_ecs_airflow_tg.arn
    container_name   = "nginxtest"
    container_port   = 80
  }

  network_configuration {
    subnets         = [aws_subnet.public.id, aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.alb_to_ecs_traffic.id]
  }
}

# resource "aws_ecs_task_set" "nginxtesttask" {
#   service         = aws_ecs_service.nginxtestservice.id
#   cluster         = aws_ecs_cluster.test_airflow.id
#   task_definition = aws_ecs_task_definition.nginxtestfamily.arn

#   load_balancer {
#     target_group_arn = aws_lb_target_group.alb_ecs_airflow_tg.arn
#     container_name   = "nginx"
#     container_port   = 80
#   }
# }



# module "task_definition" {
#   source = "../.."

#   execution_role   = null
#   image            = "nginx"
#   image_tag        = var.image_tag
#   memory           = 64
#   log_group        = aws_cloudwatch_log_group.log.name
#   ports            = var.ports
#   network_mode     = var.network_mode
#   task_role        = "ecs-task-role"
#   namespace        = var.namespace
#   name             = var.name
#   type             = "default"
#   health_check     = [["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost/ || exit 1"], 30, 2, 3]
#   volumes          = var.volumes
#   mounts           = var.mounts
#   task_environment = var.task_environment
#   docker_labels    = var.docker_labels
# }



