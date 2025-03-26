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

## Deployment Workflow

### 1. Initial Setup

1. **Configure AWS Credentials**:

   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Enter your default region (e.g., us-east-1)
   # Enter your output format (json)
   ```
2. **Create terraform.tfvars**:

   ```hcl
   environment = "production"
   project     = "konnichiwa"
   region      = "us-east-1"
   vpc_cidr    = "10.0.0.0/16"

   private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
   public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

   availability_zones = ["us-east-1a", "us-east-1b"]

   ecs_task_cpu    = 1024
   ecs_task_memory = 2048
   ```

### 2. Infrastructure Deployment

1. **Initialize Terraform**:

   ```bash
   terraform init
   ```
2. **Review Changes**:

   ```bash
   terraform plan -out=tfplan
   ```
3. **Apply Changes**:

   ```bash
   terraform apply tfplan
   ```
4. **Verify Deployment**:

   ```bash
   # Get ALB DNS name
   terraform output alb_dns_name

   # Get ECR repository URL
   terraform output ecr_repository_url

   # Get ECS cluster name
   terraform output ecs_cluster_name
   ```

### 3. Post-Deployment Tasks

1. **Configure API Key**:

   ```bash
   # Generate API key
   API_KEY=$(openssl rand -base64 32)

   # Store in Secrets Manager
   aws secretsmanager create-secret \
     --name test-api-key \
     --secret-string "{\"API_KEY\":\"$API_KEY\"}"
   ```
2. **Update ECS Service**:

   ```bash
   # Get the task definition ARN
   TASK_DEF_ARN=$(aws ecs describe-task-definition \
     --task-definition konnichiwa \
     --query 'taskDefinition.taskDefinitionArn' \
     --output text)

   # Update the service
   aws ecs update-service \
     --cluster konnichiwa-cluster \
     --service konnichiwa-service \
     --task-definition $TASK_DEF_ARN \
     --force-new-deployment
   ```

### 4. Monitoring Setup

1. **Enable Container Insights**:

   ```bash
   aws ecs update-cluster-settings \
     --cluster konnichiwa-cluster \
     --settings name=containerInsights,value=enabled
   ```
2. **Configure CloudWatch Alarms**:

   ```bash
   # Create CPU utilization alarm
   aws cloudwatch put-metric-alarm \
     --alarm-name konnichiwa-cpu-utilization \
     --metric-name CPUUtilization \
     --namespace ECS/ContainerInsights \
     --statistic Average \
     --period 300 \
     --threshold 70 \
     --comparison-operator GreaterThanThreshold \
     --evaluation-periods 2 \
     --alarm-actions arn:aws:sns:us-east-1:YOUR_ACCOUNT_ID:konnichiwa-alerts
   ```

### 5. Maintenance Tasks

1. **Update Container Image**:

   ```bash
   # Build and push new image
   docker build -t konnichiwa-api .
   docker tag konnichiwa-api:latest $ECR_REPO_URL:latest
   docker push $ECR_REPO_URL:latest

   # Force new deployment
   aws ecs update-service \
     --cluster konnichiwa-cluster \
     --service konnichiwa-service \
     --force-new-deployment
   ```
2. **Clean Up Resources**:

   ```bash
   # Remove unused images
   aws ecr batch-delete-image \
     --repository-name konnichiwa \
     --image-ids imageTag=untagged

   # Clean up CloudWatch logs
   aws logs delete-log-group \
     --log-group-name /ecs/konnichiwa
   ```

## Troubleshooting

1. **ECS Service Issues**:

   ```bash
   # Check service events
   aws ecs describe-services \
     --cluster konnichiwa-cluster \
     --services konnichiwa-service

   # Check task status
   aws ecs list-tasks \
     --cluster konnichiwa-cluster \
     --service-name konnichiwa-service
   ```
2. **Load Balancer Issues**:

   ```bash
   # Check target health
   aws elbv2 describe-target-health \
     --target-group-arn $(terraform output -raw target_group_arn)

   # Check ALB access logs
   aws s3 ls s3://$(terraform output -raw alb_logs_bucket)/
   ```
3. **Container Issues**:

   ```bash
   # Get container logs
   aws logs get-log-events \
     --log-group-name /ecs/konnichiwa \
     --log-stream-name $(aws logs describe-log-streams \
       --log-group-name /ecs/konnichiwa \
       --order-by LastEventTime \
       --descending \
       --limit 1 \
       --query 'logStreams[0].logStreamName' \
       --output text)
   ```
