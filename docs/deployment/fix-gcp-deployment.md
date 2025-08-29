# 🔧 Fix for Google Cloud Deployment

## The Issue
Your GCP service account key has binary characters that can't be parsed as JSON.

## Solution: Create a New Service Account Key

### Step 1: Create New Service Account
```bash
# Login to gcloud
gcloud auth login

# Set project
gcloud config set project static-operator-469115-h1

# Create service account
gcloud iam service-accounts create addtocloud-github \
    --description="Service account for GitHub Actions" \
    --display-name="AddToCloud GitHub Actions"

# Grant necessary roles
gcloud projects add-iam-policy-binding static-operator-469115-h1 \
    --member="serviceAccount:addtocloud-github@static-operator-469115-h1.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding static-operator-469115-h1 \
    --member="serviceAccount:addtocloud-github@static-operator-469115-h1.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.admin"

gcloud projects add-iam-policy-binding static-operator-469115-h1 \
    --member="serviceAccount:addtocloud-github@static-operator-469115-h1.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

# Create and download key
gcloud iam service-accounts keys create gcp-sa-key.json \
    --iam-account=addtocloud-github@static-operator-469115-h1.iam.gserviceaccount.com
```

### Step 2: Format the JSON Key
```bash
# Make sure the JSON is properly formatted (single line, no newlines)
cat gcp-sa-key.json | jq -c .
```

### Step 3: Update GitHub Secret
Copy the **entire output** from the `jq -c .` command and paste it as the `GCP_SA_KEY` secret.

The format should look like:
```json
{"type":"service_account","project_id":"static-operator-469115-h1","private_key_id":"...","private_key":"-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n","client_email":"...","client_id":"...","auth_uri":"...","token_uri":"..."}
```

## Alternative: Use GitHub CLI
```bash
# Copy the formatted JSON and set secret
gh secret set GCP_SA_KEY < gcp-sa-key.json
```
