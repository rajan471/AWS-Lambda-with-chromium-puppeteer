FROM public.ecr.aws/lambda/nodejs:22

# Install development tools and dependencies for aws-lambda-ric
RUN dnf update -y && dnf install -y \
    gcc \
    gcc-c++ \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    unzip \
    tar \
    gzip

# Download and install Chrome
RUN curl -o /tmp/google-chrome-stable.rpm https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm && \
    rpm -i --nodeps --force /tmp/google-chrome-stable.rpm && \
    rm /tmp/google-chrome-stable.rpm

# Install additional dependencies that might be needed for Chrome
RUN dnf install -y \
    libXScrnSaver \
    atk \
    gtk3 \
    cups-libs \
    libXcomposite \
    alsa-lib \
    libXrandr \
    pango \
    libXcursor \
    libXi \
    libXtst \
    libXinerama \
    && dnf clean all

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# Set working directory
WORKDIR /var/task

# Copy package.json and install dependencies
COPY package.json ./
RUN npm install --production

# Install AWS Lambda Runtime Interface Client locally
RUN npm install aws-lambda-ric

# Copy test file and run test
COPY test-puppeteer.js ./
RUN node test-puppeteer.js && rm test-puppeteer.js

# Copy function code
COPY index.js ./

# Set the CMD to your handler
CMD ["index.handler"] 