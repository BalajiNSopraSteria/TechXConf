provider "azurerm" {
  skip_provider_registration = true
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# ====================================================================
# NETWORKING AND SECURITY INFRASTRUCTURE
# ====================================================================

# Resource Group for AI Research Infrastructure
resource "azurerm_resource_group" "ai_research_rg" {
  name     = "ai-research-rg"
  location = "eastus"

  tags = {
    Environment = "production"
    Purpose     = "AI-Research"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "ai_research_vnet" {
  name                = "ai-research-vnet"
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = "production"
    Purpose     = "AI-Research"
  }
}

# Subnets
resource "azurerm_subnet" "ml_training_subnet" {
  name                 = "ml-training-subnet"
  resource_group_name  = azurerm_resource_group.ai_research_rg.name
  virtual_network_name = azurerm_virtual_network.ai_research_vnet.name
  address_prefixes     = ["10.0.10.0/24"]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]
}

resource "azurerm_subnet" "ml_inference_subnet" {
  name                 = "ml-inference-subnet"
  resource_group_name  = azurerm_resource_group.ai_research_rg.name
  virtual_network_name = azurerm_virtual_network.ai_research_vnet.name
  address_prefixes     = ["10.0.20.0/24"]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault"
  ]
}

resource "azurerm_subnet" "data_subnet" {
  name                 = "data-subnet"
  resource_group_name  = azurerm_resource_group.ai_research_rg.name
  virtual_network_name = azurerm_virtual_network.ai_research_vnet.name
  address_prefixes     = ["10.0.30.0/24"]

  service_endpoints = [
    "Microsoft.Storage"
  ]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.ai_research_rg.name
  virtual_network_name = azurerm_virtual_network.ai_research_vnet.name
  address_prefixes     = ["10.0.40.0/24"]
}

resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet" # Must be named this exactly
  resource_group_name  = azurerm_resource_group.ai_research_rg.name
  virtual_network_name = azurerm_virtual_network.ai_research_vnet.name
  address_prefixes     = ["10.0.50.0/26"]
}

# Network Security Groups
resource "azurerm_network_security_group" "ml_training_nsg" {
  name                = "ml-training-nsg"
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name

  # Ingress Rules
  security_rule {
    name                       = "AllowSSHFromBastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPSInternal"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowDistributedTraining"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000-9000"
    source_address_prefix      = "10.0.10.0/24"
    destination_address_prefix = "10.0.10.0/24"
  }

  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Egress Rules
  security_rule {
    name                       = "AllowHTTPSOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowStorageOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Storage"
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Security"
  }
}

resource "azurerm_network_security_group" "ml_inference_nsg" {
  name                = "ml-inference-nsg"
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name

  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Security"
  }
}

resource "azurerm_network_security_group" "data_nsg" {
  name                = "data-nsg"
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name

  security_rule {
    name                       = "AllowStorageAccess"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Security"
  }
}

# NSG Associations
resource "azurerm_subnet_network_security_group_association" "ml_training_nsg_assoc" {
  subnet_id                 = azurerm_subnet.ml_training_subnet.id
  network_security_group_id = azurerm_network_security_group.ml_training_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "ml_inference_nsg_assoc" {
  subnet_id                 = azurerm_subnet.ml_inference_subnet.id
  network_security_group_id = azurerm_network_security_group.ml_inference_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "data_nsg_assoc" {
  subnet_id                 = azurerm_subnet.data_subnet.id
  network_security_group_id = azurerm_network_security_group.data_nsg.id
}

# Azure Firewall Public IP
resource "azurerm_public_ip" "firewall_pip" {
  name                = "firewall-public-ip"
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "production"
  }
}

# Azure Firewall
resource "azurerm_firewall" "ai_research_firewall" {
  name                = "ai-research-firewall"
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "firewall-ip-config"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Security"
  }
}

# ====================================================================
# SECURITY AND COMPLIANCE INFRASTRUCTURE
# ====================================================================

# Azure Key Vault
resource "azurerm_key_vault" "ai_research_kv" {
  name                        = "ai-research-kv-${substr(md5(azurerm_resource_group.ai_research_rg.id), 0, 8)}"
  location                    = azurerm_resource_group.ai_research_rg.location
  resource_group_name         = azurerm_resource_group.ai_research_rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = "00000000-0000-0000-0000-000000000000"
  soft_delete_retention_days  = 90
  purge_protection_enabled    = true
  sku_name                    = "premium"

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [
      azurerm_subnet.ml_training_subnet.id,
      azurerm_subnet.ml_inference_subnet.id
    ]
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Security"
    Compliance  = "Required"
  }
}

# DDoS Protection Plan
resource "azurerm_network_ddos_protection_plan" "ai_research_ddos" {
  name                = "ai-research-ddos-plan"
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Security"
  }
}

# ====================================================================
# ORIGINAL RESOURCES (Updated with Security)
# ====================================================================

# Network Interface for original VM
resource "azurerm_network_interface" "my_linux_vm_nic" {
  name                = "test-nic"
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ml_training_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Environment = "production"
    Service     = "web-app"
  }
}

resource "azurerm_linux_virtual_machine" "my_linux_vm" {
  location            = azurerm_resource_group.ai_research_rg.location
  name                = "test"
  resource_group_name = azurerm_resource_group.ai_research_rg.name
  admin_username      = "testuser"
  admin_password      = "Testpa5s"
  disable_password_authentication = false

  size = "Standard_F16s"

  tags = {
    Environment = "production"
    Service     = "web-app"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_encryption_set_id = null
  }

  network_interface_ids = [
    azurerm_network_interface.my_linux_vm_nic.id,
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
resource "azurerm_network_interface" "ml_gpu_vm_nic" {
  name                = "ml-gpu-vm-nic"
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ml_training_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "ml_gpu_vm" {
  location            = azurerm_resource_group.ai_research_rg.location
  name                = "ml-gpu-vm-nc6"
  resource_group_name = azurerm_resource_group.ai_research_rg.name
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
    azurerm_network_interface.ml_gpu_vm_nic.id,
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
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name
  dns_prefix          = "mlaks"

  default_node_pool {
    name           = "default"
    node_count     = 2
    vm_size        = "Standard_D4s_v3"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    service_cidr       = "10.1.0.0/16"
    dns_service_ip     = "10.1.0.10"
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
  resource_group_name      = azurerm_resource_group.ai_research_rg.name
  location                 = azurerm_resource_group.ai_research_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version = "TLS1_2"

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [azurerm_subnet.data_subnet.id]
    bypass                     = ["AzureServices"]
  }

  blob_properties {
    versioning_enabled = true
  }

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

# ====================================================================
# SCALED AI RESEARCH INFRASTRUCTURE - $250K Monthly Budget
# ====================================================================

# Large-scale GPU VM cluster - ND A100 v4 series
resource "azurerm_network_interface" "ml_gpu_cluster_a100_nic" {
  count               = 20
  name                = "ml-gpu-a100-nic-${count.index + 1}"
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ml_training_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "ml_gpu_cluster_a100" {
  count               = 20
  location            = azurerm_resource_group.ai_research_rg.location
  name                = "ml-gpu-a100-${count.index + 1}"
  resource_group_name = azurerm_resource_group.ai_research_rg.name
  admin_username      = "azureuser"
  admin_password      = "P@ssw0rd1234!"

  size = "Standard_ND96asr_v4" # 8x A100 GPUs, 96 cores, 900GB RAM

  disable_password_authentication = false

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Training"
    Workload    = "AI-DL"
    GPU         = "A100"
    Cluster     = "gpu-cluster-a100"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 2048
  }

  network_interface_ids = [
    azurerm_network_interface.ml_gpu_cluster_a100_nic[count.index].id,
  ]

  source_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "ubuntu-hpc"
    sku       = "2004"
    version   = "latest"
  }
}

# Medium GPU VMs - NC A100 v4 series
resource "azurerm_network_interface" "ml_gpu_cluster_nc_nic" {
  count               = 30
  name                = "ml-gpu-nc-nic-${count.index + 1}"
  location            = azurerm_resource_group.ai_research_rg.location
  resource_group_name = azurerm_resource_group.ai_research_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ml_training_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "ml_gpu_cluster_nc" {
  count               = 30
  location            = azurerm_resource_group.ai_research_rg.location
  name                = "ml-gpu-nc-${count.index + 1}"
  resource_group_name = azurerm_resource_group.ai_research_rg.name
  admin_username      = "azureuser"
  admin_password      = "P@ssw0rd1234!"

  size = "Standard_NC24ads_A100_v4" # 1x A100 GPU, 24 cores, 220GB RAM

  disable_password_authentication = false

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Training"
    Workload    = "AI-DL"
    GPU         = "A100"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 1024
  }

  network_interface_ids = [
    azurerm_network_interface.ml_gpu_cluster_nc_nic[count.index].id,
  ]

  source_image_reference {
    publisher = "microsoft-dsvm"
    offer     = "ubuntu-2004"
    sku       = "2004-gen2"
    version   = "latest"
  }
}

# Azure Machine Learning Compute Clusters
resource "azurerm_machine_learning_compute_cluster" "aml_gpu_cluster" {
  name                          = "aml-gpu-compute-cluster"
  location                      = azurerm_resource_group.ai_research_rg.location
  machine_learning_workspace_id = azurerm_machine_learning_workspace.ml_workspace.id
  vm_priority                   = "Dedicated"
  vm_size                       = "Standard_NC24ads_A100_v4"

  scale_settings {
    min_node_count                       = 10
    max_node_count                       = 50
    scale_down_nodes_after_idle_duration = "PT30M"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Compute"
    Workload    = "AI-DL"
  }
}

# Additional compute cluster for CPU-intensive preprocessing
resource "azurerm_machine_learning_compute_cluster" "aml_cpu_cluster" {
  name                          = "aml-cpu-compute-cluster"
  location                      = "eastus"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.ml_workspace.id
  vm_priority                   = "Dedicated"
  vm_size                       = "Standard_D96as_v5"

  scale_settings {
    min_node_count                       = 20
    max_node_count                       = 100
    scale_down_nodes_after_idle_duration = "PT15M"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Preprocessing"
    Workload    = "AI-DL"
  }
}

# Premium Storage Account for high-performance data access
resource "azurerm_storage_account" "ml_premium_storage" {
  name                     = "mlpremiumstorageresearch"
  resource_group_name      = "test"
  location                 = "eastus"
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "BlockBlobStorage"

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Storage"
    Workload    = "AI-DL"
  }
}

# NetApp Files for ultra-high performance parallel storage
resource "azurerm_netapp_account" "ml_netapp" {
  name                = "ml-netapp-research"
  resource_group_name = "test"
  location            = "eastus"

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Storage"
    Workload    = "AI-DL"
  }
}

resource "azurerm_netapp_pool" "ml_netapp_pool" {
  name                = "ml-netapp-pool"
  account_name        = azurerm_netapp_account.ml_netapp.name
  location            = "eastus"
  resource_group_name = "test"
  service_level       = "Ultra"
  size_in_tb          = 100

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Storage"
    Workload    = "AI-DL"
  }
}

# Scaled AKS cluster for distributed inference
resource "azurerm_kubernetes_cluster" "ml_aks_research" {
  name                = "ml-aks-research-cluster"
  location            = "eastus"
  resource_group_name = "test"
  dns_prefix          = "mlaksresearch"

  default_node_pool {
    name       = "system"
    node_count = 5
    vm_size    = "Standard_D8s_v5"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Inference"
    Workload    = "AI-DL"
  }
}

# Large GPU node pool for AKS
resource "azurerm_kubernetes_cluster_node_pool" "ml_aks_gpu_large" {
  name                  = "gpularge"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.ml_aks_research.id
  vm_size               = "Standard_NC24ads_A100_v4"
  node_count            = 25

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Inference"
    Workload    = "AI-DL"
    GPU         = "A100"
  }
}

# Databricks Premium workspace with autoscaling clusters
resource "azurerm_databricks_workspace" "ml_databricks_research" {
  name                = "ml-databricks-research"
  resource_group_name = "test"
  location            = "eastus"
  sku                 = "premium"

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Analytics"
    Workload    = "AI-DL"
  }
}

# Azure Synapse Analytics for large-scale data processing
resource "azurerm_synapse_workspace" "ml_synapse" {
  name                                 = "ml-synapse-research"
  resource_group_name                  = "test"
  location                             = "eastus"
  storage_data_lake_gen2_filesystem_id = "/subscriptions/123/resourceGroups/test/providers/Microsoft.Storage/storageAccounts/storage/blobServices/default/containers/data"
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = "P@ssw0rd1234!"

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Analytics"
    Workload    = "AI-DL"
  }
}

# Azure Synapse Spark Pool for distributed ML
resource "azurerm_synapse_spark_pool" "ml_spark_pool" {
  name                 = "mlsparkpool"
  synapse_workspace_id = azurerm_synapse_workspace.ml_synapse.id
  node_size_family     = "MemoryOptimized"
  node_size            = "XXLarge"
  node_count           = 50
  spark_version        = "3.4"

  auto_scale {
    max_node_count = 100
    min_node_count = 20
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Processing"
    Workload    = "AI-DL"
  }
}

# Azure Container Registry for ML models and containers
resource "azurerm_container_registry" "ml_acr" {
  name                = "mlresearchacr"
  resource_group_name = "test"
  location            = "eastus"
  sku                 = "Premium"
  admin_enabled       = true

  georeplications {
    location = "westus"
  }

  georeplications {
    location = "westeurope"
  }

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Containers"
    Workload    = "AI-DL"
  }
}

# Multiple Managed Disks for data staging
resource "azurerm_managed_disk" "ml_data_disks" {
  count                = 20
  name                 = "ml-data-disk-${count.index + 1}"
  location             = "eastus"
  resource_group_name  = "test"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = 4096

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Data"
    Workload    = "AI-DL"
  }
}

# Azure Monitor for comprehensive logging
resource "azurerm_log_analytics_workspace" "ml_monitoring" {
  name                = "ml-research-monitoring"
  location            = "eastus"
  resource_group_name = "test"
  sku                 = "PerGB2018"
  retention_in_days   = 90

  tags = {
    Environment = "production"
    Purpose     = "AI-Research-Monitoring"
    Workload    = "AI-DL"
  }
}
