#!/bin/bash

echo "Building Lambda Container..."

# Set your AWS account ID and region
AWS_ACCOUNT_ID="266735811373"
AWS_REGION="ap-south-1"
REPOSITORY_NAME="puppeteer-lambda"
IMAGE_TAG="latest"

# Clean up any existing Docker image
echo "Cleaning up existing Docker image..."
docker rmi ${REPOSITORY_NAME}:${IMAGE_TAG} 2>/dev/null || true  

# Build the Docker image
echo "Building Docker image..."
docker build -t ${REPOSITORY_NAME}:${IMAGE_TAG} .
if [ $? -ne 0 ]; then
    echo "Docker build failed!"
    exit 1
fi

# Create ECR repository if it doesn't exist
echo "Creating ECR repository (if it doesn't exist)..."
aws ecr create-repository --repository-name ${REPOSITORY_NAME} --region ${AWS_REGION} 2>/dev/null || true

# Get ECR login token
echo "Logging into ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
if [ $? -ne 0 ]; then
    echo "ECR login failed!"
    exit 1
fi

# Tag the image for ECR
echo "Tagging image for ECR..."
docker tag ${REPOSITORY_NAME}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:${IMAGE_TAG}

# Push the image to ECR
echo "Pushing image to ECR..."
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:${IMAGE_TAG}
if [ $? -ne 0 ]; then
    echo "Docker push failed!"
    exit 1
fi

echo "Container built and pushed successfully!"
echo ""
echo "ECR Image URI: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPOSITORY_NAME}:${IMAGE_TAG}"
echo ""
echo "Next steps:"
echo "1. Create a Lambda function using container image"
echo "2. Use the ECR Image URI above"
echo "3. Set memory to at least 1024MB"
echo "4. Set timeout to at least 30 seconds"
