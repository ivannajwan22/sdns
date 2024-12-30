# Stage 1: Build Stage using alpine for minimal dependencies
FROM alpine:latest AS builder

# Install build dependencies
RUN apk --no-cache add \
    ca-certificates \
    gcc \
    git \
    musl-dev \
    go

# Set working directory
WORKDIR /src

# Copy source code into the container
COPY . .

# Build the sdns binary with static linking
RUN CGO_ENABLED=0 go build -trimpath -ldflags "-s -w" -o /sdns

# Stage 2: Runtime Stage using scratch for minimal runtime
FROM scratch

# Copy certificates for TLS support
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy the compiled sdns binary
COPY --from=builder /sdns /sdns

# Expose necessary ports for sdns
EXPOSE 53/tcp
EXPOSE 53/udp
EXPOSE 853
EXPOSE 8053
EXPOSE 8080

# Set the binary as the entrypoint
ENTRYPOINT ["/sdns"]
