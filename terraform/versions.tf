terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0, < 6.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
  backend "gcs" {
    bucket = "forge-platform-11124-tfstate"
    prefix = "terraform/state"
  }
}
