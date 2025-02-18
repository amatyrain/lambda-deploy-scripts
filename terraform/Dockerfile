FROM hashicorp/terraform:latest

# Install required packages
RUN apk add --no-cache \
    python3 \
    python3-dev \
    py3-pip \
    bash \
    gcc \
    musl-dev \
    linux-headers

# Set working directory
WORKDIR /app
