# Use Eclipse Temurin 25 (Java 25)
FROM eclipse-temurin:25-jre-alpine

# Set working directory
WORKDIR /hytale

# Install dependencies
# su-exec: allow stepping down from root to user
# libc6-compat & gcompat: required for glibc-linked binaries (Netty/Quiche) on Alpine
# libgcc: required by libnetty_quiche
RUN apk add --no-cache curl unzip libc6-compat gcompat libgcc su-exec

# Download and install Hytale Downloader CLI
RUN curl -L https://downloader.hytale.com/hytale-downloader.zip -o /tmp/downloader.zip && \
    unzip /tmp/downloader.zip -d /tmp/downloader && \
    find /tmp/downloader -name "*linux*" -type f -exec cp {} /usr/local/bin/hytale-downloader-linux \; && \
    chmod +x /usr/local/bin/hytale-downloader-linux && \
    rm -rf /tmp/downloader /tmp/downloader.zip

# Create a non-root user
RUN addgroup -S hytale && adduser -S hytale -G hytale

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# The volume where server files will be stored
VOLUME /hytale

# Hytale uses QUIC over UDP
EXPOSE 5520/udp

# We MUST start as root to fix volume permissions on the host-mounted directory
USER root

ENTRYPOINT ["/entrypoint.sh"]
