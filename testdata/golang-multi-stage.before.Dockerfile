# Created from patterns seen at https://github.com/AlphaWong/go-test-multi-stage-build
# This Dockerfile demonstrates a multi-stage Go build with package optimization

# Build stage
FROM golang:1.20.1 AS builder

WORKDIR /app

# Copy go.mod and go.sum files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

# Install UPX for binary compression (optional)
RUN apt-get update && apt-get install -y wget xz-utils
RUN wget -P /tmp/ https://github.com/upx/upx/releases/download/v3.95/upx-3.95-amd64_linux.tar.xz
RUN tar xvf /tmp/upx-3.95-amd64_linux.tar.xz -C /tmp
RUN mv /tmp/upx-3.95-amd64_linux/upx /usr/local/bin/upx

# Compress the binary to reduce size
RUN upx --ultra-brute -qq app && \
    upx -t app

# Final stage
FROM alpine:3.17

# Install any runtime dependencies
RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/app .

# Create a non-root user
RUN adduser -D appuser
USER appuser

# Command to run
ENTRYPOINT ["/app/app"] 