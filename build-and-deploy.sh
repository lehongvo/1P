#!/bin/bash

# Quick build and deploy script for GCP
# This script builds and deploys all services to GCP

set -e

PROJECT_ID="supple-cabinet-470303-d8"
REGION="asia-southeast1"

echo "🚀 Building and deploying all services to GCP..."

# Build and push all services
echo "🏗️ Building phoenix-oms..."
docker build --platform linux/amd64 -f phoenix-oms/Dockerfile -t gcr.io/$PROJECT_ID/phoenix-oms .
docker push gcr.io/$PROJECT_ID/phoenix-oms

echo "🏗️ Building phoenix-commerce..."
docker build --platform linux/amd64 -f phoenix-commerce/Dockerfile -t gcr.io/$PROJECT_ID/phoenix-commerce .
docker push gcr.io/$PROJECT_ID/phoenix-commerce

echo "🏗️ Building mock-data..."
docker build --platform linux/amd64 -f mock/Dockerfile -t gcr.io/$PROJECT_ID/mock-data .
docker push gcr.io/$PROJECT_ID/mock-data

# Deploy phoenix-oms
echo "🚀 Deploying phoenix-oms..."
gcloud run deploy phoenix-oms \
    --image gcr.io/$PROJECT_ID/phoenix-oms \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port=3001 \
    --set-env-vars="NODE_ENV=production,DB_NAME=lotus_o2o,DB_USER=lotus_user,DB_PASSWORD=lotus_password,DB_HOST=/cloudsql/supple-cabinet-470303-d8:asia-southeast1:lotus-o2o-postgres,DB_PORT=5432" \
    --add-cloudsql-instances=supple-cabinet-470303-d8:asia-southeast1:lotus-o2o-postgres \
    --project=$PROJECT_ID

# Get phoenix-oms URL
OMS_URL=$(gcloud run services describe phoenix-oms --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
echo "📍 Phoenix OMS URL: $OMS_URL"

# Deploy phoenix-commerce
echo "🚀 Deploying phoenix-commerce..."
gcloud run deploy phoenix-commerce \
    --image gcr.io/$PROJECT_ID/phoenix-commerce \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port=3002 \
    --set-env-vars="NODE_ENV=production,DB_NAME=lotus_o2o,DB_USER=lotus_user,DB_PASSWORD=lotus_password,DB_HOST=/cloudsql/supple-cabinet-470303-d8:asia-southeast1:lotus-o2o-postgres,DB_PORT=5432,OMS_API_URL=$OMS_URL" \
    --add-cloudsql-instances=supple-cabinet-470303-d8:asia-southeast1:lotus-o2o-postgres \
    --project=$PROJECT_ID

# Deploy mock-data
echo "🚀 Deploying mock-data..."
gcloud run deploy mock-data \
    --image gcr.io/$PROJECT_ID/mock-data \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port=8080 \
    --set-env-vars="NODE_ENV=production,DB_NAME=lotus_o2o,DB_USER=lotus_user,DB_PASSWORD=lotus_password,DB_HOST=/cloudsql/supple-cabinet-470303-d8:asia-southeast1:lotus-o2o-postgres,DB_PORT=5432" \
    --add-cloudsql-instances=supple-cabinet-470303-d8:asia-southeast1:lotus-o2o-postgres \
    --project=$PROJECT_ID

# Get all service URLs
COMMERCE_URL=$(gcloud run services describe phoenix-commerce --region=$REGION --project=$PROJECT_ID --format="value(status.url)")
MOCK_URL=$(gcloud run services describe mock-data --region=$REGION --project=$PROJECT_ID --format="value(status.url)")

echo "✅ Deployment completed!"
echo ""
echo "🌐 Your services are now available at:"
echo "   Phoenix OMS: $OMS_URL"
echo "   Phoenix Commerce: $COMMERCE_URL"
echo "   Mock Data: $MOCK_URL"
echo ""
echo "💡 Test your services:"
echo "   curl $OMS_URL/api/v1/monitor/recent?minutes=60"
echo "   curl $COMMERCE_URL/api/v1/health"
echo "   curl $MOCK_URL"
