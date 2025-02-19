# Providers ----------------------------------------------------------------------------------------
provider "azurerm" {
  features {}
}

# Locals -------------------------------------------------------------------------------------------
locals {
  current_date = formatdate("YYYY-MM-DD", timestamp())
  start_number = var.lab_start_number
}

# Data Sources -------------------------------------------------------------------------------------
data "azurerm_resource_group" "cloud_workshop" {
  name     = var.azurerm_workshop_resource_group_name
}

data "azurerm_shared_image_version" "apm_platform" {
  name                = var.azurerm_shared_image_version
  image_name          = var.azurerm_shared_image_definition
  gallery_name        = var.azurerm_shared_image_gallery
  resource_group_name = var.azurerm_images_resource_group_name
}

# Modules ------------------------------------------------------------------------------------------

# Resources ----------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.azurerm_resource_name_prefix}-${local.current_date}"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = data.azurerm_resource_group.cloud_workshop.name
  location            = data.azurerm_resource_group.cloud_workshop.location
  tags                = var.resource_tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${var.azurerm_resource_name_prefix}-${local.current_date}"
  resource_group_name  = data.azurerm_resource_group.cloud_workshop.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.azurerm_resource_name_prefix}-${local.current_date}"
  resource_group_name = data.azurerm_resource_group.cloud_workshop.name
  location            = data.azurerm_resource_group.cloud_workshop.location
  tags                = var.resource_tags
}

resource "azurerm_network_security_rule" "allow_icmp" {
  name                        = "security-rule-allow-icmp-${var.azurerm_resource_name_prefix}-${local.current_date}"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = var.azurerm_source_address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.cloud_workshop.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "allow_internal" {
  name                        = "security-rule-allow-internal-${var.azurerm_resource_name_prefix}-${local.current_date}"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = ["10.0.1.0/24"]
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.cloud_workshop.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "security-rule-allow-ssh-${var.azurerm_resource_name_prefix}-${local.current_date}"
  priority                    = 102
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.azurerm_source_address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.cloud_workshop.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "allow_apm_platform" {
  name                        = "security-rule-allow-apm-platform-${var.azurerm_resource_name_prefix}-${local.current_date}"
  priority                    = 103
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443", "3306", "8080", "8090", "9080", "9191"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.cloud_workshop.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_public_ip" "apm_platform" {
  name  = var.lab_count > 1 || var.lab_use_num_suffix ? format("%s-%02d-public-ip-%s", var.azurerm_resource_name_prefix, count.index + local.start_number, local.current_date) : "${var.azurerm_resource_name_prefix}-public-ip-${local.current_date}"
  count = var.lab_count

  resource_group_name     = data.azurerm_resource_group.cloud_workshop.name
  location                = data.azurerm_resource_group.cloud_workshop.location
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = var.azurerm_lab_tcp_idle_timeout
  tags                    = var.resource_tags
}

resource "azurerm_network_interface" "apm_platform" {
  name  = var.lab_count > 1 || var.lab_use_num_suffix ? format("%s-%02d-network-interface-%s", var.azurerm_resource_name_prefix, count.index + local.start_number, local.current_date) : "${var.azurerm_resource_name_prefix}-network-interface-${local.current_date}"
  count = var.lab_count

  resource_group_name = data.azurerm_resource_group.cloud_workshop.name
  location            = data.azurerm_resource_group.cloud_workshop.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.apm_platform[count.index].id
  }

  tags = var.resource_tags
}

resource "azurerm_network_interface_security_group_association" "apm_platform" {
  count                     = var.lab_count
  network_interface_id      = azurerm_network_interface.apm_platform[count.index].id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "apm_platform" {
  name  = var.lab_count > 1 || var.lab_use_num_suffix ? format("%s-%02d-vm-%s", var.azurerm_resource_name_prefix, count.index + local.start_number, local.current_date) : "${var.azurerm_resource_name_prefix}-vm-${local.current_date}"
  count = var.lab_count

  resource_group_name   = data.azurerm_resource_group.cloud_workshop.name
  location              = data.azurerm_resource_group.cloud_workshop.location
  computer_name         = format("%s-%02d-vm", var.azurerm_apm_platform_vm_hostname_prefix, count.index + local.start_number)
  size                  = var.azurerm_vm_size
  admin_username        = var.azurerm_ssh_username
  network_interface_ids = [azurerm_network_interface.apm_platform[count.index].id]

  custom_data = base64encode(templatefile("${path.module}/templates/user-data-sh.tmpl", {
    azurerm_ssh_username       = var.azurerm_ssh_username,
    azurerm_vm_hostname_prefix = var.azurerm_apm_platform_vm_hostname_prefix,
    azurerm_vm_domain          = "",
    azurerm_use_num_suffix     = var.lab_use_num_suffix
  }))

  admin_ssh_key {
    username   = var.azurerm_ssh_username
    public_key = file(var.lab_ssh_pub_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.azurerm_storage_account_type
  }

  source_image_id = data.azurerm_shared_image_version.apm_platform.id
  tags            = var.resource_tags
}

# create ansible trigger to generate inventory and helper files. -----------------------------------
resource "null_resource" "ansible_trigger" {
  # fire the ansible trigger when any ec2 instance requires re-provisioning.
  triggers = {
    compute_instance_ids = join(",", azurerm_linux_virtual_machine.apm_platform.*.id)
  }

  # execute the following 'local-exec' provisioners each time the trigger is invoked.
  # generate the ansible azure hosts inventory.
  provisioner "local-exec" {
    working_dir = "."
    command     = <<EOD
cat <<EOF > azure_hosts.inventory
[apm_platform_vm]
${join("\n", toset(azurerm_linux_virtual_machine.apm_platform.*.public_ip_address))}
EOF
EOD
  }
}
