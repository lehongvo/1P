# 🚀 GCP Deployment Guide for 1PService

This guide will help you deploy your application from local Docker Compose to Google Cloud Platform using Cloud Run and Cloud SQL.

## 📋 Prerequisites

1. **Google Cloud Account** with billing enabled
2. **gcloud CLI** installed and authenticated
3. **Docker** installed locally
4. A **GCP Project** created

## 🛠️ Setup Steps

### 1. Install and Configure gcloud CLI

```bash
# Install gcloud CLI (if not already installed)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Authenticate with Google Cloud
gcloud auth login

# Set your project ID
gcloud config set project YOUR_PROJECT_ID
```

### 2. Update Configuration

Edit the `deploy-gcp.sh` file and replace:
- `your-gcp-project-id` with your actual GCP project ID
- Adjust region if needed (currently set to `asia-southeast1` for Vietnam)

### 3. Make Scripts Executable

```bash
chmod +x deploy-gcp.sh
chmod +x gcp-db-init.sh
```

### 4. Deploy to GCP

```bash
./deploy-gcp.sh
```

This script will:
- ✅ Enable required GCP APIs
- 🗄️ Create Cloud SQL PostgreSQL instance
- 📊 Create database and user
- 🏗️ Build and deploy both services to Cloud Run
- 🔗 Configure service connections

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐
│  Phoenix OMS    │    │ Phoenix Commerce│
│  (Cloud Run)    │◄───┤  (Cloud Run)    │
│  Port: 3001     │    │  Port: 3002     │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          └──────────┬───────────┘
                     │
          ┌─────────────────┐
          │   Cloud SQL     │
          │  (PostgreSQL)   │
          └─────────────────┘
```

## 🔧 Alternative Deployment Methods

### Method 1: Using Cloud Build (Recommended for CI/CD)

```bash
# Trigger build and deployment
gcloud builds submit --config=cloudbuild.yaml .
```

### Method 2: Manual Docker Build and Push

```bash
# Build images
docker build -f phoenix-oms/Dockerfile -t gcr.io/YOUR_PROJECT_ID/phoenix-oms .
docker build -f phoenix-commerce/Dockerfile -t gcr.io/YOUR_PROJECT_ID/phoenix-commerce .

# Push to Google Container Registry
docker push gcr.io/YOUR_PROJECT_ID/phoenix-oms
docker push gcr.io/YOUR_PROJECT_ID/phoenix-commerce

# Deploy to Cloud Run
gcloud run deploy phoenix-oms --image gcr.io/YOUR_PROJECT_ID/phoenix-oms --region asia-southeast1
gcloud run deploy phoenix-commerce --image gcr.io/YOUR_PROJECT_ID/phoenix-commerce --region asia-southeast1
```

## 🗄️ Database Setup

### Initialize Database Schema

If you have an `init.sql` file in the `database/` directory:

1. Upload it to Google Cloud Storage:
```bash
gsutil cp database/init.sql gs://your-bucket-name/
```

2. Run the initialization script:
```bash
./gcp-db-init.sh
```

### Connect to Cloud SQL

```bash
# Connect via gcloud
gcloud sql connect lotus-postgres --user=lotus_user --database=lotus_o2o

# Or get connection details for external tools
gcloud sql instances describe lotus-postgres
```

## 🔐 Environment Variables

The deployment automatically configures these environment variables:

**Phoenix OMS:**
- `NODE_ENV=production`
- `DB_HOST=/cloudsql/CONNECTION_NAME`
- `DB_PORT=5432`
- `DB_NAME=lotus_o2o`
- `DB_USER=lotus_user`
- `DB_PASSWORD=lotus_password`
- `PORT=3001`

**Phoenix Commerce:**
- All OMS variables plus:
- `OMS_API_URL=https://phoenix-oms-url`
- `PORT=3002`

## 💰 Cost Optimization

- **Cloud Run**: Pay only for requests (very cost-effective)
- **Cloud SQL**: Consider `db-f1-micro` for development (cheapest tier)
- **Container Registry**: Minimal storage costs

## 🔍 Monitoring and Logs

```bash
# View Cloud Run logs
gcloud logs read --service=phoenix-oms
gcloud logs read --service=phoenix-commerce

# View Cloud SQL logs
gcloud sql operations list --instance=lotus-postgres
```

## 🌐 Custom Domain (Optional)

1. Map custom domain in Cloud Run console
2. Configure DNS records
3. SSL certificates are automatically managed

## 🚨 Troubleshooting

### Common Issues:

1. **Build fails**: Check Dockerfile paths and dependencies
2. **Database connection fails**: Verify Cloud SQL instance is running
3. **Service unreachable**: Check IAM permissions and firewall rules

### Debug Commands:

```bash
# Check service status
gcloud run services list

# View service details
gcloud run services describe phoenix-oms --region=asia-southeast1

# Check Cloud SQL status
gcloud sql instances list
```

## 🔄 Updates and Rollbacks

```bash
# Deploy new version
./deploy-gcp.sh

# Rollback to previous version
gcloud run services update-traffic phoenix-oms --to-revisions=REVISION_NAME=100
```

## 📞 Support

If you encounter issues:
1. Check the [Cloud Run documentation](https://cloud.google.com/run/docs)
2. Review [Cloud SQL documentation](https://cloud.google.com/sql/docs)
3. Check GCP Console logs and monitoring

---

🎉 **Congratulations!** Your application is now running on Google Cloud Platform with enterprise-grade scalability and reliability.
