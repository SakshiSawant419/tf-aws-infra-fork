# Infrastructure Setup with Terraform

## Prerequisites
Ensure you have the following installed:
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [AWS CLI](https://aws.amazon.com/cli/)
- An AWS account with necessary IAM permissions
- GitHub repository with CI workflows configured

## Setup Instructions

### 1. Clone the Repository
```sh
git clone <repo-url>
cd <repo>
```

### 2. Configure AWS Credentials
Ensure your AWS credentials are set up for the `dev` profile.
```sh
aws configure --profile dev
```

### 3. Initialize Terraform
Run the following command to initialize the Terraform project:
```sh
terraform init
```

### 4. Validate Configuration
Check if your Terraform configuration is valid:
```sh
terraform validate
```

### 5. Plan Deployment
Generate an execution plan to preview changes:
```sh
terraform plan -var-file=dev.tfvars
```

### 6. Apply Changes
Apply the configuration to create the infrastructure:
```sh
terraform apply -var-file=dev.tfvars
```

### 7. Destroy Infrastructure (If Needed)
To delete the infrastructure, run:
```sh
terraform destroy -var-file=dev.tfvars
```

## Continuous Integration (CI)
This repository includes a GitHub Actions workflow for CI:
- **Terraform CI**: Runs `terraform fmt` and `terraform validate` on every pull request.
- **Branch Protection**: Ensures only passing PRs can be merged.

