#!/bin/bash

# Database initialization script for Cloud SQL
# Run this after deploying to GCP to initialize your database

set -e

PROJECT_ID="supple-cabinet-470303-d8"  # Your GCP project ID
DB_INSTANCE_NAME="lotus-o2o-postgres"
DB_NAME="lotus_o2o"

echo "🗄️ Initializing Cloud SQL database..."

# Check if init.sql exists
if [ -f "./database/init.sql" ]; then
    echo "📋 Found init.sql, executing directly on Cloud SQL..."
    
    # Execute SQL file directly using psql
    PGPASSWORD=lotus_password psql -h 34.142.150.197 -U lotus_user -d $DB_NAME -f ./database/init.sql
    
    echo "✅ Database initialized successfully!"
else
    echo "⚠️ No init.sql found in ./database/ directory"
    echo "Please create your database schema manually or upload init.sql"
fi

echo "🔍 To connect to your Cloud SQL instance:"
echo "gcloud sql connect $DB_INSTANCE_NAME --user=lotus_user --database=$DB_NAME --project=$PROJECT_ID"
