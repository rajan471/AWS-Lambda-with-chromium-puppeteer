# Ready-to-Use Chromium + Puppeteer Image for AWS Lambda (Container Image)

This container image provides a preconfigured environment for running Puppeteer with Chromium in AWS Lambda using the container image format. It exposes a Lambda-compatible handler function that accepts a JSON payload with the following fields:

`htmlTemplate` – The HTML content to be rendered.

`fileName` – The desired name for the generated PDF file.

The Lambda function launches a headless Chromium browser, renders the provided HTML content, generates a PDF named as specified, and uploads it to a designated S3 bucket.

This solution is ideal for serverless HTML-to-PDF generation at scale with minimal setup.


## Environment variables
`AWS_REGION`
`S3_BUCKET_NAME`
