terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.66"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment      = var.environment == "" ? "dev" : var.environment
  application_name = var.environment == "" ? var.application_name : "${var.application_name}-${local.environment}"
  resource_group   = "rg-${local.application_name}-001"
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group
  location = var.location

  tags = {
    "terraform"   = "true"
    "environment" = local.environment
  }
}

resource "random_uuid" "deploymentName" {}

resource "azurerm_logic_app_workflow" "la-test" {
  name                = "la-test"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

data "local_file" "dnLogicApp" {
  filename = "${path.module}/../logic-apps/heartbeat/workflow.json"
}

resource "azurerm_template_deployment" "la-test-workflow" {
  resource_group_name = azurerm_resource_group.main.name
  deployment_mode     = "Incremental"
  name                = random_uuid.deploymentName.result
  parameters = {
    workflows_flow_name = azurerm_logic_app_workflow.la-test.name
    location            = var.location
  }
  template_body = data.local_file.dnLogicApp.content
}


module "key-vault" {
  source           = "./modules/key-vault"
  resource_group   = azurerm_resource_group.main.name
  application_name = local.application_name
  environment      = local.environment
  location         = var.location
}
