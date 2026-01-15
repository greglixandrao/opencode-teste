variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "fastapi-app"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "github_repository" {
  description = "GitHub repository (format: owner/repo)"
  type        = string
}

variable "docker_hub_username" {
  description = "Docker Hub username"
  type        = string
}

variable "docker_image_name" {
  description = "Docker Hub image name"
  type        = string
  default     = "fastapi-app"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
  default     = "fastapi-cluster"
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
  default     = "fastapi-service"
}

variable "ecs_task_family" {
  description = "ECS task definition family"
  type        = string
  default     = "fastapi-task"
}

variable "task_cpu" {
  description = "CPU units for task"
  type        = string
  default     = "256"
}

variable "task_memory" {
  description = "Memory for task"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Desired count of tasks"
  type        = number
  default     = 1
}
