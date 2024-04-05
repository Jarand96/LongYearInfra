terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.97.1"
    }
  }
}

# Configure the GitHub Provider
provider "github" {}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}
