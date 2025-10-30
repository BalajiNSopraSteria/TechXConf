provider "azurerm" {
  skip_provider_registration = true
  features {}
}

resource "azurerm_linux_virtual_machine" "my_linux_vm" {
  location            = "eastus"
  name                = "test"
  resource_group_name = "test"
  admin_username      = "testuser"
  admin_password      = "Testpa5s"

  size = "Standard_F16s" # <<<<<<<<<< Try changing this to Standard_F16s_v2 to compare the costs

  tags = {
    Environment = "production"
    Service     = "web-app"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface_ids = [
    "/subscriptions/123/resourceGroups/testrg/providers/Microsoft.Network/networkInterfaces/testnic",
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_service_plan" "my_app_service" {
  location            = "eastus"
  name                = "test"
  resource_group_name = "test_resource_group"
  os_type             = "Windows"

  sku_name     = "P1v2"
  worker_count = 4 # <<<<<<<<<< Try changing this to 8 to compare the costs

  tags = {
    Environment = "Prod"
    Service     = "web-app"
  }
}

resource "azurerm_linux_function_app" "my_function" {
  location                   = "eastus"
  name                       = "test"
  resource_group_name        = "test"
  service_plan_id            = "/subscriptions/123/resourceGroups/testrg/providers/Microsoft.Web/serverFarms/serverFarmValue"
  storage_account_name       = "test"
  storage_account_access_key = "test"
  site_config {}

  tags = {
    Environment = "Prod"
  }
}

# Azure Machine Learning Workspace
resource "azurerm_machine_learning_workspace" "ml_workspace" {
  name                = "ml-workspace-prod"
  location            = "eastus"
  resource_group_name = "test"
  application_insights_id = "/subscriptions/123/resourceGroups/testrg/providers/microsoft.insights/components/appinsights"
  key_vault_id       = "/subscriptions/123/resourceGroups/testrg/providers/Microsoft.KeyVault/vaults/keyvault"
  storage_account_id = "/subscriptions/123/resourceGroups/testrg/providers/Microsoft.Storage/storageAccounts/storage"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "production"
    Purpose     = "ML-Platform"
    Workload    = "AI-DL"
  }
}

# GPU-enabled Virtual Machine for deep learning
resource "azurerm_linux_virtual_machine" "ml_gpu_vm" {
  location            = "eastus"
  name                = "ml-gpu-vm-nc6"
  resource_group_name = "test"
  admin_username      = "azureuser"
  admin_password      = "P@ssw0rd1234!"

  size = "Standard_NC6" # GPU instance with NVIDIA K80

  disable_password_authentication = false

  tags = {
    Environment = "production"
    Purpose     = "ML-Training"
    Workload    = "AI-DL"
    GPU         = "K80"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 512
  }

  network_interface_ids = [
    "/subscriptions/123/resourceGroups/testrg/providers/Microsoft.Network/networkInterfaces/mlnic",
  ]

  source_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "ubuntu-2004"
    sku       = "2004-gen2"
    version   = "latest"
  }
}

# Azure Kubernetes Service for ML model serving
resource "azurerm_kubernetes_cluster" "ml_aks" {
  name                = "ml-aks-cluster"
  location            = "eastus"
  resource_group_name = "test"
  dns_prefix          = "mlaks"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_D4s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "production"
    Purpose     = "ML-Inference"
    Workload    = "AI-DL"
  }
}

# GPU node pool for AKS
resource "azurerm_kubernetes_cluster_node_pool" "ml_gpu_nodes" {
  name                  = "gpupool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.ml_aks.id
  vm_size               = "Standard_NC6s_v3" # GPU nodes with V100
  node_count            = 2

  tags = {
    Environment = "production"
    Purpose     = "ML-Training"
    Workload    = "AI-DL"
    GPU         = "V100"
  }
}

# Azure Cognitive Services Account
resource "azurerm_cognitive_account" "cognitive_services" {
  name                = "cognitive-services-ml"
  location            = "eastus"
  resource_group_name = "test"
  kind                = "CognitiveServices"
  sku_name            = "S0"

  tags = {
    Environment = "production"
    Purpose     = "AI-Services"
    Workload    = "AI-DL"
  }
}

# Azure Storage Account for ML datasets
resource "azurerm_storage_account" "ml_storage" {
  name                     = "mlstorageprodeast"
  resource_group_name      = "test"
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = {
    Environment = "production"
    Purpose     = "ML-DataStorage"
    Workload    = "AI-DL"
  }
}

# Azure Container Instance for ML inference
resource "azurerm_container_group" "ml_inference" {
  name                = "ml-inference-container"
  location            = "eastus"
  resource_group_name = "test"
  os_type             = "Linux"

  container {
    name   = "ml-model-server"
    image  = "mcr.microsoft.com/azureml/onnxruntime:latest"
    cpu    = "2"
    memory = "4"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = {
    Environment = "production"
    Purpose     = "ML-Inference"
    Workload    = "AI-DL"
  }
}

# Azure Databricks Workspace for big data ML
resource "azurerm_databricks_workspace" "ml_databricks" {
  name                = "ml-databricks-workspace"
  resource_group_name = "test"
  location            = "eastus"
  sku                 = "premium"

  tags = {
    Environment = "production"
    Purpose     = "ML-Analytics"
    Workload    = "AI-DL"
  }
}
