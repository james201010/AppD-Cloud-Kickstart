# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.0.11"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = ">= 4.2, < 5.0"
    }

    null = {
      source = "hashicorp/null"
      version = ">= 3.1"
    }
  }
}
