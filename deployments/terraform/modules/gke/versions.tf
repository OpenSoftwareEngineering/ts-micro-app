terraform {
  required_version = ">= 1.5.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.73"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.22"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
  }
}