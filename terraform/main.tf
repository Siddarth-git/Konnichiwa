terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # N. Virginia region
}

# VPC and Network Configuration
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "test-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true  # For cost optimization in development

  tags = {
    Environment = "production"
    Project     = "test"
  }
}

# ECR Repository
resource "aws_ecr_repository" "test" {
  name = "test-api"
  
  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "production"
    Project     = "test"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "test" {
  name = "test-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Environment = "production"
    Project     = "test"
  }
}

# Task Definition
resource "aws_ecs_task_definition" "test" {
  family                   = "test-api"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = 1024  # 1 vCPU
  memory                  = 2048  # 2GB
  execution_role_arn      = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "test-api"
      image = "${aws_ecr_repository.test.repository_url}:latest"
      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = "4000"
        }
      ]
      secrets = [
        {
          name      = "API_KEY"
          valueFrom = aws_secretsmanager_secret.api_key.arn
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/test-api"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Environment = "production"
    Project     = "test"
  }
}

# ECS Service
resource "aws_ecs_service" "test" {
  name            = "test-service"
  cluster         = aws_ecs_cluster.test.id
  task_definition = aws_ecs_task_definition.test.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.test.arn
    container_name   = "test-api"
    container_port   = 4000
  }

  depends_on = [aws_lb_listener.test]

  tags = {
    Environment = "production"
    Project     = "test"
  }
}

# Application Load Balancer
resource "aws_lb" "test" {
  name               = "test-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = module.vpc.public_subnets

  tags = {
    Environment = "production"
    Project     = "test"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "test" {
  name        = "test-tg"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    timeout             = 5
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }

  tags = {
    Environment = "production"
    Project     = "test"
  }
}

# ALB Listener
resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.test.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test.arn
  }

  tags = {
    Environment = "production"
    Project     = "test"
  }
}

# Security Groups
resource "aws_security_group" "alb" {
  name        = "test-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "production"
    Project     = "test"
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "test-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 4000
    to_port         = 4000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = "production"
    Project     = "test"
  }
}

# IAM Roles
resource "aws_iam_role" "ecs_execution_role" {
  name = "test-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "test-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Secrets Manager
resource "aws_secretsmanager_secret" "api_key" {
  name = "test-api-key"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "test" {
  name              = "/ecs/test-api"
  retention_in_days = 30

  tags = {
    Environment = "production"
    Project     = "test"
  }
} 