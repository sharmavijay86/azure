provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

# Define the resource group
resource "azurerm_resource_group" "aks_qatar_ipay_dev_rg" {
  name     = "aks_qatar_ipay_dev_rg"
  location = "Qatar"
}

# Define the virtual network
resource "azurerm_virtual_network" "aks_qatar_ipay_dev_vnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.aks_qatar_ipay_dev_rg.location
  resource_group_name = azurerm_resource_group.aks_qatar_ipay_dev_rg.name
}

# Define the first subnet within the virtual network
resource "azurerm_subnet" "aks_qatar_ipay_dev_subnet1" {
  name                 = "aks_qatar_ipay_dev_subnet1"
  resource_group_name  = azurerm_resource_group.aks_qatar_ipay_dev_rg.name
  virtual_network_name = azurerm_virtual_network.aks_qatar_ipay_dev_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define the second subnet within the virtual network
resource "azurerm_subnet" "aks_qatar_ipay_dev_subnet2" {
  name                 = "aks_qatar_ipay_dev_subnet2"
  resource_group_name  = azurerm_resource_group.aks_qatar_ipay_dev_rg.name
  virtual_network_name = azurerm_virtual_network.aks_qatar_ipay_dev_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Define the AKS cluster
resource "azurerm_kubernetes_cluster" "aks_qatar_ipay_dev" {
  name                = "aks_qatar_ipay_dev"
  location            = azurerm_resource_group.aks_qatar_ipay_dev_rg.location
  resource_group_name = azurerm_resource_group.aks_qatar_ipay_dev_rg.name
  dns_prefix          = "aks-qatar-ipay-dev"
  kubernetes_version  = "1.27.0"

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_DS2_v2"
    os_disk_size_gb = 50

    vnet_subnet_id = azurerm_subnet.aks_qatar_ipay_dev_subnet1.id
  }

  node_pool "app_pool" {
    name            = "app-pool"
    node_count      = var.app_pool_min_size
    min_count       = var.app_pool_min_size
    max_count       = var.app_pool_max_size
    vm_size         = "Standard_DS2_v2"
    os_disk_size_gb = 50

    vnet_subnet_ids = var.subnet_ids

    pod_cidr = "192.168.0.0/16"

    node_labels = {
      "app" = "app-node"
    }

    taint {
      key    = "app"
      value  = "true"
      effect = "NoSchedule"
    }

    tolerations {
      key      = "app"
      operator = "Equal"
      value    = "true"
      effect   = "NoSchedule"
    }
  }

  network_profile {
    network_plugin     = "azure"
    dns_service_ip     = "10.2.0.10"
    service_cidr       = "10.2.0.0/24"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  tags = var.tags
}
