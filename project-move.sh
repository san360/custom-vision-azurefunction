#!/bin/bash

# Load environment variables if .env file exists
set -o allexport
if [ -f .env ]; then
    source .env
else
    echo "Warning: .env file not found. Make sure environment variables are set."
    echo "Required variables: SOURCE_ENDPOINT, SOURCE_PROJECT_ID, SOURCE_TRAINING_KEY, TARGET_ENDPOINT, TARGET_TRAINING_KEY, PROJECT_NAME"
fi
set +o allexport

# Validate required environment variables
if [ -z "$SOURCE_ENDPOINT" ] || [ -z "$SOURCE_PROJECT_ID" ] || [ -z "$SOURCE_TRAINING_KEY" ] || [ -z "$TARGET_ENDPOINT" ] || [ -z "$TARGET_TRAINING_KEY" ] || [ -z "$PROJECT_NAME" ]; then
    echo "Error: Missing required environment variables"
    echo "Required: SOURCE_ENDPOINT, SOURCE_PROJECT_ID, SOURCE_TRAINING_KEY, TARGET_ENDPOINT, TARGET_TRAINING_KEY, PROJECT_NAME"
    exit 1
fi

# Remove trailing slashes from endpoints to avoid double slashes in URLs
SOURCE_ENDPOINT=$(echo "$SOURCE_ENDPOINT" | sed 's:/*$::')
TARGET_ENDPOINT=$(echo "$TARGET_ENDPOINT" | sed 's:/*$::')

echo "Starting export from source project..."

# Initiate export and capture the response
EXPORT_RESPONSE=$(curl -s -X GET "${SOURCE_ENDPOINT}/customvision/v3.3/Training/projects/${SOURCE_PROJECT_ID}/export" \
  -H "Training-Key: $SOURCE_TRAINING_KEY" \
  -H "Content-Type: application/json")

echo "Export response: $EXPORT_RESPONSE"

# Extract token from the export response JSON
TOKEN=$(echo "$EXPORT_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
    echo "Error: Could not extract token from export response"
    exit 1
fi

echo "Extracted token: $TOKEN"

# Wait a moment for export to be ready (optional, but recommended)
echo "Waiting for export to be ready..."
sleep 5

# Import to target environment using the token
echo "Importing project into target resource..."
IMPORT_RESPONSE=$(curl -v -G -X POST "${TARGET_ENDPOINT}/customvision/v3.3/training/projects/import" \
  --data-urlencode "token=$TOKEN" \
  --data-urlencode "name=$PROJECT_NAME" \
  -H "Training-key: $TARGET_TRAINING_KEY" \
  -H "Content-Length: 0")

echo "Import response: $IMPORT_RESPONSE"

echo "Project clone completed successfully."
