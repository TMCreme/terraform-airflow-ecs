


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
