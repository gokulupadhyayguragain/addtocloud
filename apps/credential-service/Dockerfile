# Multi-stage build for Go application
FROM golang:1.21-alpine AS builder

# Install dependencies for building
RUN apk add --no-cache git ca-certificates

# Set working directory
WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o credential-service .

# Final stage - minimal image
FROM alpine:latest

# Install ca-certificates and wget for health checks
RUN apk --no-cache add ca-certificates wget

# Create non-root user
RUN addgroup -g 1001 -S addtocloud && \
    adduser -S -D -H -u 1001 -h /app -s /sbin/nologin -G addtocloud -g addtocloud addtocloud

WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /app/credential-service .
COPY --from=builder /app/public ./public

# Change ownership
RUN chown -R addtocloud:addtocloud /app

# Switch to non-root user
USER addtocloud

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Set environment variables
ENV GIN_MODE=release
ENV API_PORT=8080

# Run the application
CMD ["./credential-service"]
