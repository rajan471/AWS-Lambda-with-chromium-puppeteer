const puppeteer = require("puppeteer");
const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const crypto = require("crypto");

// Initialize S3 client
const s3Client = new S3Client({
  region: process.env.AWS_REGION || "us-east-1",
});

exports.handler = async (event, context) => {
  console.log("Lambda HTML to PDF function started");
  console.log("Event:", JSON.stringify(event, null, 2));

  let browser = null;

  try {
    // Parse the event body to get htmlTemplate
    let requestBody;
    if (typeof event.body === "string") {
      requestBody = JSON.parse(event.body);
    } else {
      requestBody = event.body || event;
    }

    const { htmlTemplate, fileName } = requestBody;

    if (!htmlTemplate) {
      return {
        statusCode: 400,
        body: JSON.stringify({
          error: "Missing htmlTemplate in request body",
          message: "Please provide htmlTemplate in the request body",
        }),
      };
    }

    console.log("HTML template received, length:", htmlTemplate.length);
    console.log("Testing Puppeteer with Chrome...");

    browser = await puppeteer.launch({
      args: [
        "--no-sandbox",
        "--disable-setuid-sandbox",
        "--disable-dev-shm-usage",
        "--disable-session-crashed-bubble",
        "--disable-accelerated-2d-canvas",
        "--no-first-run",
        "--no-zygote",
        "--noerrdialogs",
        "--disable-gpu",
      ],
      headless: true,
      ignoreHTTPSErrors: true,
      protocolTimeout: 120000,
    });

    console.log("✅ Browser launched successfully");

    const page = await browser.newPage();
    await page.setContent(
      htmlTemplate ||
        "<html><body><h1>Test PDF Generation</h1><p>This is a test document.</p></body></html>"
    );

    console.log("✅ Page content set successfully");

    const pdf = await page.pdf({
      format: "A4",
      printBackground: true,
      margin: {
        top: "0px",
        right: "0px",
        bottom: "0px",
        left: "0px",
      },
    });

    console.log("✅ PDF generated successfully, size:", pdf.length, "bytes");

    // Generate unique filename
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const pdfName = `certificates/${fileName || timestamp}.pdf`;

    // Upload to S3
    const bucketName =
      process.env.S3_BUCKET_NAME || "warranty-management-uploads";
    console.log("Uploading PDF to S3 bucket:", bucketName);

    const uploadParams = {
      Bucket: bucketName,
      Key: pdfName,
      Body: pdf,
      ContentType: "application/pdf",
      Metadata: {
        "generated-at": new Date().toISOString(),
        "lambda-request-id": context.requestId,
        "content-length": pdf.length.toString(),
      },
    };

    const command = new PutObjectCommand(uploadParams);
    const uploadResult = await s3Client.send(command);

    console.log("PDF uploaded successfully to S3");
    console.log("Upload result:", uploadResult);

    // Generate S3 URL
    const s3Url = `https://${bucketName}.s3.${
      process.env.AWS_REGION || "us-east-1"
    }.amazonaws.com/${pdfName}`;

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
      },
      body: JSON.stringify({
        success: true,
        message: "PDF generated and uploaded successfully",
        data: {
          fileName: pdfName,
          s3Url: s3Url,
          bucketName: bucketName,
          fileSize: pdf.length,
          timestamp: new Date().toISOString(),
          requestId: context.requestId,
        },
      }),
    };
  } catch (error) {
    console.error("Error occurred:", error);
    console.error("Error stack:", error.stack);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({
        success: false,
        error: error.message,
        details: {
          name: error.name,
          code: error.code,
          stack: error.stack,
          timestamp: new Date().toISOString(),
          requestId: context.requestId,
        },
      }),
    };
  } finally {
    if (browser !== null) {
      console.log("Closing browser...");
      await browser.close();
      console.log("Browser closed successfully");
    }
    console.log("Lambda HTML to PDF function completed");
  }
};
