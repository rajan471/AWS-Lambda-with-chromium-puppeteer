const puppeteer = require("puppeteer");

async function testPuppeteer() {
  console.log("Testing Puppeteer with Chrome...");

  try {
    const browser = await puppeteer.launch({
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
      "<html><body><h1>Test PDF Generation</h1><p>This is a test document.</p></body></html>"
    );

    console.log("✅ Page content set successfully");

    const pdf = await page.pdf({
      format: "A4",
      printBackground: true,
    });

    console.log("✅ PDF generated successfully, size:", pdf.length, "bytes");

    await browser.close();
    console.log("✅ Browser closed successfully");
    console.log("🎉 All tests passed! Puppeteer is working correctly.");
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    console.error("Stack trace:", error.stack);
    process.exit(1);
  }
}

testPuppeteer();
