# Schools API

This module provides a geospatial API for querying school districts and retrieving associated data from a DynamoDB table based on latitude and longitude. It processes shapefiles, builds spatial indexes, and deploys an AWS Lambda-based API with Terraform.

---

## Table of Contents

1. [Overview](#overview)
2. [Setup Instructions](#setup-instructions)
3. [Processing Shapefiles](#processing-shapefiles)
4. [Building the Lambda Container](#building-the-lambda-container)
5. [Terraform Deployment](#terraform-deployment)
6. [API Functionality](#api-functionality)
7. [File Structure](#file-structure)

---

## Overview

The Schools API module includes the following components:

1. **Shapefile Processing**: Converts school district shapefiles into a GeoParquet format and builds a spatial index.
2. **AWS Lambda Function**: A containerized function that:
   - Queries the spatial index to find the school district based on latitude/longitude.
   - Looks up district-specific data in a DynamoDB table.
3. **Infrastructure as Code**: Terraform files to deploy the Lambda function, API Gateway, DynamoDB table, and associated resources.

---

## Setup Instructions

### Prerequisites

1. Python 3.8+
2. Docker
3. AWS CLI configured
4. Terraform CLI installed

### Step 1: Environment Setup

1. **Install Python Dependencies**  
   Run the setup script to install necessary Python packages:

   ```bash
   python3 setup_env.py
   ```

   This script installs dependencies from `requirements.txt`.

2. **Process Shapefiles**  
   Navigate to the `src` directory and run `main.py` to convert the shapefile and build the spatial index:
   ```bash
   cd src
   python3 main.py
   ```
   This generates:
   - `output/school_districts.parquet`
   - `output/spatial_index.idx`
   - `output/spatial_index.dat`

---

## Processing Shapefiles

The `main.py` script performs the following:

1. Converts the shapefile (`.shp`) to a GeoParquet file for efficient querying.
2. Builds a spatial index (`.idx`, `.dat`) using the R-tree data structure.

Ensure the input shapefile (`data/sources/EDGE_SCHOOLDISTRICT_TL_23_SY2223.shp`) is present.

---

## Building the Lambda Container

1. **Build the Docker Image**  
   Use the provided `Dockerfile` to build the container image:

   ```bash
   docker build -t schools-api-get-lambda .
   ```

2. **Tag and Push to AWS ECR**  
   Replace `<aws_account_id>` and `<region>` with your AWS account and region:
   ```bash
   aws ecr get-login-password --region <region> --profile <profile> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com
   docker tag schools-api-get-lambda:latest <aws_account_id>.dkr.ecr.<region>.amazonaws.com/schools-api-get-lambda:latest
   docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/schools-api-get-lambda:latest
   ```

---

## Terraform Deployment

1. **Initialize Terraform**  
   Navigate to the `terraform` directory and initialize Terraform:

   ```bash
   cd terraform
   terraform init
   ```

2. **Apply Configuration**  
   Deploy the infrastructure using:
   ```bash
   terraform apply
   ```
   This creates:
   - An ECR repository for the Lambda image.
   - A Lambda function using the container image.
   - API Gateway resources.
   - DynamoDB table and IAM roles.

---

## API Functionality

### Request:

- **HTTP Method**: `GET`
- **Endpoint**: `/schools`
- **Query Parameters**:
  - `lat`: Latitude of the location.
  - `lng`: Longitude of the location.

### Workflow:

1. The Lambda function queries the spatial index to find the school district containing the specified latitude and longitude.
2. Using the district's `geoid`, it retrieves matching documents from the DynamoDB table (`schools`).

---

## File Structure

```plaintext
schools/
├── data/
│   ├── sources/
│   │   ├── EDGE_SCHOOLDISTRICT_TL_23_SY2223.shp
│   │   ├── EDGE_SCHOOLDISTRICT_TL_23_SY2223.shp.xml
│   │   └── EDGE_SCHOOLDISTRICT_TL_23_SY2223.shx
│   ├── output/
│   │   ├── school_districts.parquet
│   │   ├── spatial_index.dat
│   │   └── spatial_index.idx
├── src/
│   ├── main.py
│   ├── lambda_function.py
│   └── requirements.txt
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── ...
├── Dockerfile
├── setup_env.py
└── README.md
```

---

## Next Steps

1. Confirm all resources are deployed using Terraform.
2. Test the API with sample latitude/longitude inputs.
3. Monitor usage and logs in CloudWatch.

---

Feel free to contribute or report issues in the repository.
