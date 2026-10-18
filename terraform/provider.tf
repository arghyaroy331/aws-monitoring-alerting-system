provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project     = "aws-monitoring-alerting-system"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}
