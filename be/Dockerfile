# Build stage
FROM gradle:8.8-jdk21 AS builder

WORKDIR /app

# Copy gradle files first (for caching)
COPY gradlew build.gradle.kts settings.gradle.kts ./
COPY gradle gradle

# Copy source code
COPY src src

# Build the application
RUN chmod +x gradlew && ./gradlew bootJar --no-daemon -x test

# Runtime stage
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Copy jar from build stage
COPY --from=builder /app/build/libs/*.jar app.jar

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Change ownership
RUN chown -R appuser:appgroup /app

USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
