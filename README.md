# Konnichiwa

A simple API to greet you in Japanese.

## Overview

Konnichiwa is a Python-based API service designed to provide basic system information and a greeting. It features three endpoints:

* `/`: Returns a simple greeting.
* `/health`: Provides a health check endpoint, returning "ok" when the service is operational.
* `/inspect`: Returns a JSON response containing detailed system information (CPU usage, memory usage, uptime, etc.). This endpoint is secured with API key authentication to restrict access.

## System Requirements

- Handle 1,000 requests per second
- Maintain p95 latency under 300ms for users in Tokyo
- Protected /inspect endpoint with API key authentication

## Local Development

1. Install the following development requirements in your system:
   * Python 3.13.2
   * Poetry 2.1.1
2. In the project root directory, create a `.env` file and set the `API_KEY` environment variable.
3. Install dependencies: `poetry install`
4. Run the application:
   ```bash
   poetry run uvicorn src.api.main:app --port 4000 --reload
   ```

## Docker Deployment

Build the image:
```bash
docker build -t konnichiwa-api .
```

Run the container:
```bash
docker run -p 4000:4000 -e API_KEY=your-secure-api-key konnichiwa-api
```

## Cloud Deployment (AWS)

The application is deployed on AWS ECS in the us-east-1 (N. Virginia) region.

### Live Endpoints

The API is currently deployed and accessible at:
```
http://test-alb-502768483.us-east-1.elb.amazonaws.com
```

Test the endpoints:
```bash
# Test root endpoint
curl http://test-alb-502768483.us-east-1.elb.amazonaws.com/

# Test health endpoint
curl http://test-alb-502768483.us-east-1.elb.amazonaws.com/health

# Test inspect endpoint (requires API key)
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://test-alb-502768483.us-east-1.elb.amazonaws.com/inspect
```

### Infrastructure Components

- **ECS Cluster**: Running on Fargate for serverless container management
- **Application Load Balancer**: For request distribution
- **ECR Repository**: For container image storage
- **Secrets Manager**: For API key management
- **CloudWatch**: For monitoring and logging

### Resource Specifications

- **ECS Service**: 2 tasks running on Fargate
- **Task Definition**: 1 vCPU, 2GB memory
- **Load Balancer**: Application Load Balancer with target group
- **Auto Scaling**: Configured to scale based on CPU utilization

## CI/CD Pipeline

The pipeline is implemented using GitHub Actions and includes:

1. **Test Stage**:
   - Python setup
   - Poetry installation
   - Dependency installation
   - Unit tests execution

2. **Deploy Stage** (on main branch):
   - AWS credentials configuration
   - ECR login
   - Docker image build and push
   - ECS service update

## API Key Management

The API key is managed securely using AWS Secrets Manager:

1. Generate a secure API key:
   ```bash
   openssl rand -base64 32
   ```

2. Store in AWS Secrets Manager:
   ```bash
   aws secretsmanager create-secret \
     --name test-api-key \
     --secret-string '{"API_KEY":"YOUR_GENERATED_KEY"}'
   ```

3. The API key is injected into the ECS tasks as an environment variable.

## Monitoring

The `monitor.py` script checks system health by:

1. Making an authenticated request to the /inspect endpoint
2. Checking CPU and memory usage against thresholds (70%)
3. Printing warning messages if usage exceeds thresholds
4. Exiting with appropriate status codes

Usage:
```bash
# Ensure you have the correct .env file configuration:
API_KEY=your-secure-api-key
API_URL=http://test-alb-502768483.us-east-1.elb.amazonaws.com

# Run the monitoring script:
poetry run python monitor.py
```

Example output:
```
System is healthy!
CPU Usage: 2%
Memory Usage: 13%
```

## Security Considerations

1. **Container Security**:
   - Non-root user in container
   - Minimal base image
   - Regular security updates

2. **API Security**:
   - API key authentication
   - Rate limiting
   - Secure secret management

3. **Infrastructure Security**:
   - VPC isolation
   - Security groups
   - IAM roles with least privilege

## Infrastructure as Code

The infrastructure is managed using Terraform:

1. **VPC Configuration**:
   - 2 Availability Zones in us-east-1
   - Public and private subnets
   - NAT Gateway for private subnet access

2. **ECS Configuration**:
   - Fargate launch type
   - Task definitions with resource limits
   - Service auto-scaling

3. **Security**:
   - IAM roles and policies
   - Security group rules
   - Secrets management

## Running Tests

```bash
poetry run pytest
```

## Testing the API

```bash
# Test root endpoint
curl http://test-alb-502768483.us-east-1.elb.amazonaws.com/

# Test health endpoint
curl http://test-alb-502768483.us-east-1.elb.amazonaws.com/health

# Test inspect endpoint (requires API key)
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://test-alb-502768483.us-east-1.elb.amazonaws.com/inspect
```