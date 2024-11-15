#!/bin/bash

# Attempt to get the access token
TOKEN=$(gcloud auth print-access-token 2>/dev/null)

# Check if the token is non-empty
if [[ -n "$TOKEN" ]]; then
    exit 0  # Success, authenticated
else
    exit 1  # Failure, not authenticated
fi