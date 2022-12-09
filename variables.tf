variable "default_region" {
  description = "The default region for resources"
  type = string
  default = "eu-west-1"
}

variable "eu_west_cidr_block" {
    description = "Cidr block for VPC"
    type = string
    default = "10.0.0.0/16"
}

variable "internet_gateway_name" {
    description = "Name of my internet gateway"
    type = string
    default = "airflow-deploy-test"
}

variable "route_table_rule" {
    description = "Name of the route table route"
    type = string 
    default = "airflow_test_rt"
}

# First subnet 
variable "first_subnet_cidr" {
    description = "Cidr block for Subnet a "
    type = string
    default = "10.0.0.0/20"
}

variable "first_subnet_az" {
    description = "Availability zone for the first subnet"
    type = string
    default = "eu-west-1a"
}

variable "first_subnet_name" {
    description = "Name of the first subnet"
    type = string 
    default = "Test_Subnet1"
}

# Second Subnet 
variable "second_subnet_cidr" {
    description = "Cidr block for Subnet b"
    type = string
    default = "10.0.16.0/20"
}

variable "second_subnet_az" {
    description = "Availability zone for the Second subnet"
    type = string
    default = "eu-west-1b"
}

variable "second_subnet_name" {
    description = "Name of the Second subnet"
    type = string 
    default = "Test_Subnet2"
}

# Security Groups
# First security group allows traffic to the ALB from internet
variable "security_group_to_internet_name" {
    description = "Security group that allow internet traffic to ALB"
    type = string
    default = "alb_to_internet_comm_allow"  
}

variable "internet_sg_from_port" {
    description = "Starting value for port range on the SG for internet traffic"
    type =  number
    default = 80
}

variable "internet_sg_to_port" {
    description = "End value for port range on the SG for internet traffic"
    type =  number
    default = 80
}

# Second security group allows traffic from the first SG to the ECS target
variable "security_group_to_ecs_name" {
    description = "Security group that allow ALB traffic to ECS target"
    type = string
    default = "ecs_to_alb_traffic_allow"  
}

variable "ecs_to_lb_sg_from_port" {
    description = "Starting value for port range on the SG for ALB traffic"
    type =  number
    default = 80
}

variable "ecs_to_lb_sg_to_port" {
    description = "End value for port range on the SG for ALB traffic"
    type =  number
    default = 80
}

# Load balancer
variable "alb_name" {
    description = "Name of the load balancer"
    type = string
    default = "alb-ecs-airflow"
}

# Target Group
variable "target_group_name" {
    description = "name of the target group"
    type = string
    default = "alb-ecs-airflow-tg"
  
}

variable "target_group_port" {
    description = "Port of the target group"
    type = number
    default = 80 
}

# Listener
variable "listener_port" {
    description = "Port of the listener"
    type = number
    default = 80
}

# CloudWatch
variable "cloudwatch_ecs_log_name" {
    description = "Name for the Log Group on Cloudwatch"
    type = string
    default = "ecs/airflow"
}

variable "cloudwatch_log_retention_days" {
    description = "Number of days to retain the logs"
    type = number
    default = 3
}

# ECS Cluster
variable "ecs_cluster_name" {
    description = "name of the Cluster"
    type = string
    default = "test_airflow"
}


variable "ecs_task_definition_family_name" {
    description = "name of the task family"
    type = string
    default = "airflowtestfamily"
}

variable "ecs_task_execution_role_arn" {
    description = "IAM Execution role for the ECS task"
    type = string
    default = "arn:aws:iam::291509689978:role/ecsTaskExecutionRole"    
}

variable "ecs_task_container_name" {
    description = "Name of the container under the task"
    type = string
    default = "airflowtest"
}

variable "ecs_container_image" {
    description = "The image to pull for deployment"
    type = string
    default = "nginx"
}

variable "ecs_container_cpu" {
    description = "CPU Size for the container"
    type = number
    default = 1024
}

variable "ecs_container_memory" {
    description = "Memory Size allocation for the Container"
    type = number 
    default = 2048
}

# ECS Service
variable "ecs_service_name" {
    description = "Name of the service under the cluster"
    type = string
    default = "airflowtestservice"
}

variable "ecs_service_launch_type" {
    description = "Launch type for the ECS Service"
    type = string
    default = "FARGATE"
  
}









# variable "sg_ingress_rules" {
#     type = list(object({
#       from_port   = number
#       to_port     = number
#       protocol    = string
#       cidr_block  = string
#       description = string
#     }))
#     default     = [
#         {
#           from_port   = 8080
#           to_port     = 8080
#           protocol    = "tcp"
#           cidr_block  = "1.2.3.4/32"
#           description = "Connection to Airflow Container service"
#         },
#         {
#           from_port   = 5432
#           to_port     = 5432
#           protocol    = "tcp"
#           cidr_block  = "1.2.3.4/32"
#           description = "Connection to Postgres DB instance"
#         },
#     ]
# }
