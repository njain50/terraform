
provider "azurerm" {
  features {

  }
}

resource "azurerm_resource_group" "main" {
name     = "${var.prefix}-${var.name}"
location = var.location

}

resource "azurerm_virtual_network" "main" {
name                = "${var.prefix}-network"
address_space       = ["10.0.0.0/16"]
location            = azurerm_resource_group.main.location
resource_group_name = azurerm_resource_group.main.name
depends_on = ["azurerm_resource_group.main"]
}

resource "azurerm_subnet" "internal" {
name                 = "internal"
resource_group_name  = azurerm_resource_group.main.name
virtual_network_name = azurerm_virtual_network.main.name
address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
count                 = length(var.vmname)
#we can only have one network interface per VM
name                = "${var.prefix}-nic-${count.index +1}"
location            = azurerm_resource_group.main.location
resource_group_name = azurerm_resource_group.main.name

ip_configuration {
name                          = "testconfiguration1"
subnet_id                     = azurerm_subnet.internal.id
private_ip_address_allocation = "Dynamic"
}
}

resource "azurerm_virtual_machine" "main" {
count                 = length(var.vmname)  
  # adding +1 as index starts with 0.
name                  = "${var.prefix}-${count.index +1}-${var.vmname[count.index]}"
location              = azurerm_resource_group.main.location
resource_group_name   = azurerm_resource_group.main.name
#we will create 3 network interface id's and each VM will get seperate network interface id
network_interface_ids = ["${element(azurerm_network_interface.main.*.id,count.index+1)}"]
vm_size               = "Standard_DS1_v2"

# Uncomment this line to delete the OS disk automatically when deleting the VM
# delete_os_disk_on_termination = true

# Uncomment this line to delete the data disks automatically when deleting the VM
delete_data_disks_on_termination = true

storage_image_reference {
publisher = "Canonical"
offer     = "UbuntuServer"
sku       = "16.04-LTS"
version   = "latest"
}
storage_os_disk {
# we can only have one unique disk  per VM
name              = "myosdisk1-${count.index+1}"
caching           = "ReadWrite"
create_option     = "FromImage"
managed_disk_type = "Standard_LRS"
}
os_profile {
computer_name  = "hostname"
admin_username = "testadmin"
admin_password = "Password1234!"
}
os_profile_linux_config {
disable_password_authentication = false
}
tags = {
environment = "staging"
}
}

output "virual_machine_location" {
  value = "${azurerm_resource_group.main.*.location}"
}

output "virual_machine_name" {
  value = "${azurerm_virtual_machine.main.*.name}"
}

output "virual_machine_network_interface" {
  value = "${azurerm_virtual_network.main.*.name}"
}

output "azurerm_subnet" {
  value = "${azurerm_subnet.internal.*.name}"
}

output "name" {
  value = "${join("," , azurerm_virtual_machine.main.*.id)}"
}