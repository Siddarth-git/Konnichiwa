# Konnichiwa Infrastructure

This directory contains the Terraform configuration for deploying the Konnichiwa API service on AWS ECS.

## Prerequisites

1. AWS CLI installed and configured with appropriate credentials
2. Terraform installed (version 1.0.0 or later)
3. AWS account with appropriate permissions

## Infrastructure Components

The configuration creates the following AWS resources:

- VPC with public and private subnets
- ECS Cluster with Fargate launch type
- ECR Repository for container images
- Application Load Balancer
- Security Groups
- IAM Roles and Policies
- CloudWatch Log Group
- Secrets Manager for API key storage

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the planned changes:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. To destroy the infrastructure:
   ```bash
   terraform destroy
   ```

## Variables

The following variables can be customized by creating a `terraform.tfvars` file:

- `environment`: Environment name (default: "production")
- `project`: Project name (default: "konnichiwa")
- `region`: AWS region (default: "ap-northeast-1")
- `vpc_cidr`: CIDR block for VPC (default: "10.0.0.0/16")
- `private_subnets`: CIDR blocks for private subnets
- `public_subnets`: CIDR blocks for public subnets
- `availability_zones`: Availability zones
- `ecs_task_cpu`: CPU units for ECS task (default: 1024)
- `ecs_task_memory`: Memory for ECS task (default: 2048)
- `ecs_service_desired_count`: Desired number of ECS tasks (default: 2)
- `container_port`: Container port (default: 4000)
- `log_retention_days`: Number of days to retain CloudWatch logs (default: 30)

## Outputs

After applying the configuration, the following outputs will be available:

- `alb_dns_name`: The DNS name of the load balancer
- `ecr_repository_url`: The URL of the ECR repository
- `ecs_cluster_name`: The name of the ECS cluster
- `ecs_service_name`: The name of the ECS service
- `vpc_id`: The ID of the VPC
- `private_subnet_ids`: The IDs of the private subnets
- `public_subnet_ids`: The IDs of the public subnets
- `secrets_manager_secret_arn`: The ARN of the Secrets Manager secret

## Security Considerations

1. The API key is stored in AWS Secrets Manager
2. ECS tasks run in private subnets
3. Security groups restrict access to necessary ports
4. IAM roles follow the principle of least privilege

## Cost Optimization

1. Single NAT Gateway for development environments
2. Fargate launch type for serverless container management
3. Configurable number of ECS tasks
4. Configurable log retention period

## Monitoring

1. Container Insights enabled on the ECS cluster
2. CloudWatch logs for container logs
3. ALB health checks configured
4. Security group monitoring

## Maintenance

1. Regular updates to the base container image
2. Monitoring of CloudWatch metrics
3. Review of security group rules
4. Backup of Secrets Manager values 