FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    postgresql-client \
    libc6 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy mock data generation script
COPY mock/generate_mock_data.sh /app/
COPY mock/clear_docker_files.sh /app/

# Make scripts executable
RUN chmod +x /app/generate_mock_data.sh
RUN chmod +x /app/clear_docker_files.sh

# Create data directory
RUN mkdir -p /app/data

# Set environment variables
ENV NODE_ENV=production
ENV DB_HOST=localhost
ENV DB_PORT=5432
ENV DB_NAME=lotus_o2o
ENV DB_USER=lotus_user
ENV DB_PASSWORD=lotus_password

# Expose port (if needed for health checks)
EXPOSE 8080

# Run the mock data generation script
CMD ["/app/generate_mock_data.sh", "--watch"]
