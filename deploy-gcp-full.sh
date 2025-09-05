#!/bin/bash

# GCP Full Deployment Script for 1PService
# Includes: phoenix-oms, phoenix-commerce, mock-data, lotus-sftp
# Make sure you have gcloud CLI installed and authenticated

set -e

# Configuration
PROJECT_ID="supple-cabinet-470303-d8"  # Your GCP project ID
REGION="asia-southeast1"  # Vietnam region
DB_INSTANCE_NAME="lotus-postgres"
DB_NAME="lotus_o2o"
DB_USER="lotus_user"
DB_PASSWORD="lotus_password"

echo "🚀 Starting full GCP deployment..."

# Enable required APIs
echo "📋 Enabling required GCP APIs..."
gcloud services enable cloudbuild.googleapis.com --project=$PROJECT_ID
gcloud services enable run.googleapis.com --project=$PROJECT_ID
gcloud services enable sqladmin.googleapis.com --project=$PROJECT_ID
gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID
gcloud services enable compute.googleapis.com --project=$PROJECT_ID

# Create Cloud SQL instance
echo "🗄️ Creating Cloud SQL PostgreSQL instance..."
gcloud sql instances create $DB_INSTANCE_NAME \
    --database-version=POSTGRES_15 \
    --tier=db-f1-micro \
    --region=$REGION \
    --project=$PROJECT_ID || echo "Instance may already exist"

# Create database
echo "📊 Creating database..."
gcloud sql databases create $DB_NAME \
    --instance=$DB_INSTANCE_NAME \
    --project=$PROJECT_ID || echo "Database may already exist"

# Set database password
echo "🔐 Setting database user password..."
gcloud sql users set-password $DB_USER \
    --instance=$DB_INSTANCE_NAME \
    --password=$DB_PASSWORD \
    --project=$PROJECT_ID || echo "User may already exist"

# Get Cloud SQL connection name
CONNECTION_NAME=$(gcloud sql instances describe $DB_INSTANCE_NAME --project=$PROJECT_ID --format="value(connectionName)")
echo "🔗 Cloud SQL connection name: $CONNECTION_NAME"

# Build and deploy phoenix-oms
echo "🏗️ Building and deploying phoenix-oms..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/phoenix-oms \
    --file=phoenix-oms/Dockerfile \
    --project=$PROJECT_ID .

gcloud run deploy phoenix-oms \
    --image gcr.io/$PROJECT_ID/phoenix-oms \
    --platform managed \
    --region=$REGION \
    --allow-unauthenticated \
    --port=3001 \
    --set-env-vars="NODE_ENV=production,DB_NAME=$DB_NAME,DB_USER=$DB_USER,DB_PASSWORD=$DB_PASSWORD,PORT=3001" \
    --add-cloudsql-instances=$CONNECTION_NAME \
    --set-env-vars="DB_HOST=/cloudsql/$CONNECTION_NAME,DB_PORT=5432" \
    --project=$PROJECT_ID

# Get phoenix-oms URL
OMS_URL=$(gcloud run services describe phoenix-oms --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
echo "📍 Phoenix OMS URL: $OMS_URL"

# Build and deploy phoenix-commerce
echo "🏗️ Building and deploying phoenix-commerce..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/phoenix-commerce \
    --file=phoenix-commerce/Dockerfile \
    --project=$PROJECT_ID .

gcloud run deploy phoenix-commerce \
    --image gcr.io/$PROJECT_ID/phoenix-commerce \
    --platform managed \
    --region=$REGION \
    --allow-unauthenticated \
    --port=3002 \
    --set-env-vars="NODE_ENV=production,DB_NAME=$DB_NAME,DB_USER=$DB_USER,DB_PASSWORD=$DB_PASSWORD,PORT=3002,OMS_API_URL=$OMS_URL" \
    --add-cloudsql-instances=$CONNECTION_NAME \
    --set-env-vars="DB_HOST=/cloudsql/$CONNECTION_NAME,DB_PORT=5432" \
    --project=$PROJECT_ID

# Get phoenix-commerce URL
COMMERCE_URL=$(gcloud run services describe phoenix-commerce --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
echo "📍 Phoenix Commerce URL: $COMMERCE_URL"

# Build and deploy mock-data service
echo "🏗️ Building and deploying mock-data service..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/mock-data \
    --file=mock/Dockerfile \
    --project=$PROJECT_ID .

gcloud run deploy mock-data \
    --image gcr.io/$PROJECT_ID/mock-data \
    --platform managed \
    --region=$REGION \
    --allow-unauthenticated \
    --port=8080 \
    --set-env-vars="NODE_ENV=production,DB_NAME=$DB_NAME,DB_USER=$DB_USER,DB_PASSWORD=$DB_PASSWORD" \
    --add-cloudsql-instances=$CONNECTION_NAME \
    --set-env-vars="DB_HOST=/cloudsql/$CONNECTION_NAME,DB_PORT=5432" \
    --project=$PROJECT_ID

# Get mock-data URL
MOCK_URL=$(gcloud run services describe mock-data --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
echo "📍 Mock Data URL: $MOCK_URL"

# Create Compute Engine instance for lotus-sftp
echo "🖥️ Creating Compute Engine instance for lotus-sftp..."
gcloud compute instances create lotus-sftp \
    --zone=asia-southeast1-a \
    --machine-type=e2-micro \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=10GB \
    --boot-disk-type=pd-standard \
    --tags=lotus-sftp \
    --project=$PROJECT_ID || echo "Instance may already exist"

# Wait for instance to be ready
echo "⏳ Waiting for instance to be ready..."
sleep 60

# Install Docker on the instance
echo "🐳 Installing Docker on lotus-sftp instance..."
gcloud compute ssh lotus-sftp --zone=asia-southeast1-a --project=$PROJECT_ID --command="
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker \$USER
"

# Deploy lotus-sftp container
echo "📦 Deploying lotus-sftp container..."
gcloud compute ssh lotus-sftp --zone=asia-southeast1-a --project=$PROJECT_ID --command="
    sudo docker run -d \
        --name lotus-sftp \
        --restart unless-stopped \
        -p 22:22 \
        -p 21:21 \
        -v /home/demo/sftp:/home/demo/sftp \
        atmoz/sftp:alpine \
        demo:lotus_password:::upload
"

# Get instance external IP
SFTP_IP=$(gcloud compute instances describe lotus-sftp --zone=asia-southeast1-a --project=$PROJECT_ID --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
echo "📍 Lotus SFTP IP: $SFTP_IP"

# Initialize database
echo "🗄️ Initializing database..."
gcloud sql connect $DB_INSTANCE_NAME --user=$DB_USER --database=$DB_NAME --project=$PROJECT_ID << EOF
$(cat database/init.sql)
EOF

echo "✅ Full deployment completed!"
echo ""
echo "🌐 Your services are now available at:"
echo "   Phoenix OMS: $OMS_URL"
echo "   Phoenix Commerce: $COMMERCE_URL"
echo "   Mock Data: $MOCK_URL"
echo "   Lotus SFTP: $SFTP_IP:22"
echo ""
echo "💡 Next steps:"
echo "   1. Test your services"
echo "   2. Configure firewall rules if needed"
echo "   3. Set up monitoring and logging"
