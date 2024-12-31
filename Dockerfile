# Stage 1: Build Stage using Alpine 3.19.4
FROM alpine:3.19.4 AS builder

# Install build dependencies, termasuk Go versi terbaru
RUN apk add --no-cache \
    ca-certificates \
    gcc \
    git \
    musl-dev \
    upx \
    curl && \
    # Download and install the latest version of Go
    curl -sSL https://golang.org/dl/go1.23.0.linux-amd64.tar.gz | tar -C /usr/local -xz && \
    ln -s /usr/local/go/bin/go /usr/bin/go && \
    mkdir -p /src

# Set working directory
WORKDIR /src

# Copy Go module files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Use ARG to support multi-arch builds
ARG TARGETARCH

# Build the sdns binary with static linking
RUN CGO_ENABLED=0 GOARCH=$TARGETARCH go build -trimpath -ldflags="-s -w" -o /sdns && \
    strip /sdns && \
    upx --ultra-brute /sdns

# Stage 2: Runtime Stage using scratch
FROM scratch

# Copy necessary files for runtime
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /sdns /sdns

# Expose ports for sdns
EXPOSE 53/tcp
EXPOSE 53/udp
EXPOSE 853
EXPOSE 8053
EXPOSE 8080

# Set the entrypoint to run the binary
ENTRYPOINT ["/sdns"]
