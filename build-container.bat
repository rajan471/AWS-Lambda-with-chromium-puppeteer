@echo off
echo Building Lambda Container...

REM Set your AWS account ID and region
set AWS_ACCOUNT_ID=266735811373
set AWS_REGION=ap-south-1
set REPOSITORY_NAME=puppeteer-lambda
set IMAGE_TAG=v2

REM Clean up any existing Docker image
echo Cleaning up existing Docker image...
docker rmi %REPOSITORY_NAME%:%IMAGE_TAG% 2>nul

REM Build the Docker image
echo Building Docker image...
docker build -t %REPOSITORY_NAME%:%IMAGE_TAG% .
if %ERRORLEVEL% neq 0 (
    echo Docker build failed!
    pause
    exit /b 1
)

REM Create ECR repository if it doesn't exist
echo Creating ECR repository (if it doesn't exist)...
aws ecr create-repository --repository-name %REPOSITORY_NAME% --region %AWS_REGION% 2>nul

REM Get ECR login token
echo Logging into ECR...
aws ecr get-login-password --region %AWS_REGION% | docker login --username AWS --password-stdin %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com
if %ERRORLEVEL% neq 0 (
    echo ECR login failed!
    pause
    exit /b 1
)

REM Tag the image for ECR
echo Tagging image for ECR...
docker tag %REPOSITORY_NAME%:%IMAGE_TAG% %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%REPOSITORY_NAME%:%IMAGE_TAG%

REM Push the image to ECR
echo Pushing image to ECR...
docker push %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%REPOSITORY_NAME%:%IMAGE_TAG%
if %ERRORLEVEL% neq 0 (
    echo Docker push failed!
    pause
    exit /b 1
)

echo Container built and pushed successfully!
echo.
echo ECR Image URI: %AWS_ACCOUNT_ID%.dkr.ecr.%AWS_REGION%.amazonaws.com/%REPOSITORY_NAME%:%IMAGE_TAG%
echo.
echo Next steps:
echo 1. Create a Lambda function using container image
echo 2. Use the ECR Image URI above
echo 3. Set memory to at least 1024MB
echo 4. Set timeout to at least 30 seconds

pause 