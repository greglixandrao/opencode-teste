# Terraform Variables Configuration File
# Valores padrão para deployment da aplicação FastAPI em AWS ECS

# AWS Configuration
aws_region = "us-west-2"

# Project Configuration
project_name = "fastapi-app"
vpc_cidr     = "10.0.0.0/16"

# GitHub OIDC Configuration
# Formato: owner/repo
github_repository = "greglixandrao/opencode-teste"

# Docker Hub Configuration
docker_hub_username = "greglixandrao"
docker_image_name   = "fastapi-app"

# ECS Configuration
ecs_cluster_name = "fastapi-cluster"
ecs_service_name = "fastapi-service"
ecs_task_family  = "fastapi-task"

# Task Definition Configuration
# Fargate CPU options: 256 (.25 vCPU), 512 (.5 vCPU), 1024 (1 vCPU), 2048 (2 vCPU), 4096 (4 vCPU)
task_cpu = "256"

# Fargate Memory options (deve ser proporcional ao CPU):
# CPU 256 = 512MB, 1024MB, 2048MB
# CPU 512 = 1024MB, 2048MB, 4096MB
# CPU 1024 = 2048MB, 4096MB, 8192MB
# CPU 2048 = 4096MB, 8192MB, 16384MB
# CPU 4096 = 8192MB, 16384MB, 30720MB
task_memory = "512"

# Service Configuration
# Número de tasks que devem rodar simultaneamente
desired_count = 1
