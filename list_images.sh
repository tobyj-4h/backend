#!/bin/bash

aws s3api list-objects --profile "Dev-Environment-AWSAdministratorAccess" --bucket "beehive-media-dev" --query "Contents[].Key" --output json | jq -r ".[]" | while read -r key; do
    echo "https://d2jytepuugzhiu.cloudfront.net/$key"
done
