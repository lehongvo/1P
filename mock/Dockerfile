FROM postgres:15

# Install required packages
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy mock data generation script
COPY generate_mock_data_cloudrun.sh /app/
COPY clear_docker_files.sh /app/

# Make scripts executable
RUN chmod +x /app/generate_mock_data_cloudrun.sh
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

# Run the Cloud Run version of mock data generation
CMD ["/app/generate_mock_data_cloudrun.sh"]
