#!/bin/bash

# Deploy only Cloud Run services (skip Cloud SQL creation)
# Using existing Cloud SQL instance: lotus-o2o-postgres

set -e

# Configuration
PROJECT_ID="supple-cabinet-470303-d8"
REGION="asia-southeast1"
DB_INSTANCE_NAME="lotus-o2o-postgres"  # Using existing instance
DB_NAME="lotus_o2o"
DB_USER="lotus_user"
DB_PASSWORD="lotus_password"

echo "🚀 Deploying Cloud Run services only..."

# Get Cloud SQL connection name
CONNECTION_NAME=$(gcloud sql instances describe $DB_INSTANCE_NAME --project=$PROJECT_ID --format="value(connectionName)")
echo "🔗 Using Cloud SQL connection: $CONNECTION_NAME"

# Build and deploy phoenix-oms
echo "🏗️ Building phoenix-oms..."
docker build -f phoenix-oms/Dockerfile -t gcr.io/$PROJECT_ID/phoenix-oms .
echo "📤 Pushing phoenix-oms to registry..."
docker push gcr.io/$PROJECT_ID/phoenix-oms

gcloud run deploy phoenix-oms \
    --image gcr.io/$PROJECT_ID/phoenix-oms \
    --platform managed \
    --region=$REGION \
    --allow-unauthenticated \
    --port=3001 \
    --set-env-vars="NODE_ENV=production,DB_NAME=$DB_NAME,DB_USER=$DB_USER,DB_PASSWORD=$DB_PASSWORD" \
    --add-cloudsql-instances=$CONNECTION_NAME \
    --set-env-vars="DB_HOST=/cloudsql/$CONNECTION_NAME,DB_PORT=5432" \
    --project=$PROJECT_ID

# Get phoenix-oms URL
OMS_URL=$(gcloud run services describe phoenix-oms --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
echo "📍 Phoenix OMS URL: $OMS_URL"

# Build and deploy phoenix-commerce
echo "🏗️ Building phoenix-commerce..."
docker build -f phoenix-commerce/Dockerfile -t gcr.io/$PROJECT_ID/phoenix-commerce .
echo "📤 Pushing phoenix-commerce to registry..."
docker push gcr.io/$PROJECT_ID/phoenix-commerce

gcloud run deploy phoenix-commerce \
    --image gcr.io/$PROJECT_ID/phoenix-commerce \
    --platform managed \
    --region=$REGION \
    --allow-unauthenticated \
    --port=3002 \
    --set-env-vars="NODE_ENV=production,DB_NAME=$DB_NAME,DB_USER=$DB_USER,DB_PASSWORD=$DB_PASSWORD,OMS_API_URL=$OMS_URL" \
    --add-cloudsql-instances=$CONNECTION_NAME \
    --set-env-vars="DB_HOST=/cloudsql/$CONNECTION_NAME,DB_PORT=5432" \
    --project=$PROJECT_ID

# Get phoenix-commerce URL
COMMERCE_URL=$(gcloud run services describe phoenix-commerce --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
echo "📍 Phoenix Commerce URL: $COMMERCE_URL"

echo "✅ Cloud Run deployment completed!"
echo ""
echo "🌐 Your services are now available at:"
echo "   Phoenix OMS: $OMS_URL"
echo "   Phoenix Commerce: $COMMERCE_URL"
