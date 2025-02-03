provider "aws" {
  region = "us-west-2"
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = var.gcp_project
  region  = "us-central1"
}

# AWS EC2 Instance
resource "aws_instance" "aws_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  tags = {
    Name = "TerraformAWSInstance"
  }
}

# Azure Resource Group
resource "azurerm_resource_group" "resource_group" {
  name     = "resourceGroup"
  location = "WestUS"
}

# Azure Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}

# Azure Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Azure Public IP
resource "azurerm_public_ip" "public_ip" {
  name                = "publicIp"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Dynamic"
}

# Azure Network Interface
resource "azurerm_network_interface" "network_interface" {
  name                = "networkInterface"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "ipConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Azure Virtual Machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "vm"
  location              = azurerm_resource_group.resource_group.location
  resource_group_name   = azurerm_resource_group.resource_group.name
  network_interface_ids = [azurerm_network_interface.network_interface.id]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name          = "myosdisk1"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testuser"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# GCP Instance
resource "google_compute_instance" "gcp_instance" {
  name         = "gcp-instance"
  machine_type = "f1-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    startup-script = <<-EOF
      #!/bin/bash
      echo 'Hello, world!' > /var/www/html/index.html
    EOF
  }
}

# Output instance IDs
output "aws_instance_id" {
  value = aws_instance.aws_instance.id
}

output "azure_vm_id" {
  value = azurerm_virtual_machine.vm.id
}

output "gcp_instance_id" {
  value = google_compute_instance.gcp_instance.id
}
