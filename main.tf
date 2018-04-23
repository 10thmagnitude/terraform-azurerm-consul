terraform {
  required_version = ">= 0.10.0"
}

data "azurerm_resource_group" "consul" {
  name = "${var.resource_group_name}"
}

data "template_file" "cfg" {
  count    = "${var.cluster_size}"
  template = "${file("${path.module}/files/consul-config-json")}"

  vars {
    node_name             = "${format("${var.computer_name_prefix}-%02d", 1 + count.index)}"
    datacenter            = "${var.location}"
    cluster_size          = "${var.cluster_size}"
    node_ip_address       = "${azurerm_network_interface.consul.*.private_ip_address[count.index]}"
    join_ip_address       = "${azurerm_network_interface.consul.0.private_ip_address}"
    consul_install_path   = "${var.consul_install_path}"
    tls_key_file_path     = "${var.tls_key_file_path}"
    tls_cert_file_path    = "${var.tls_cert_file_path}"
    tls_ca_file_path      = "${var.tls_ca_file_path}"
    gossip_encryption_key = "${var.gossip_encryption_key}"
    http_api_port         = "${var.http_api_port}"
    is_node_server        = "${var.create_as_server == "1" ? true : false }"
    is_ui_enabled         = "${(var.create_as_server && count.index == 0) ? true : false }"
  }
}

data "template_file" "custom_data_consul" {
  count    = "${var.cluster_size}"
  template = "${file("${path.module}/files/consul-run-sh")}"

  vars {
    consul_config = "${data.template_file.cfg.*.rendered[count.index]}"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# AVAILABILITY SET FOR CONSUL NODES
#---------------------------------------------------------------------------------------------------------------------

resource "azurerm_availability_set" "consul" {
  name                = "${var.cluster_prefix}"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.consul.name}"
  managed             = true

  tags = "${var.tags}"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE NETWORK INTERFACES TO RUN CONSUL
#---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_interface" "consul" {
  count               = "${var.cluster_size}"
  name                = "${format("${var.computer_name_prefix}-%02d", 1 + count.index)}"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.consul.name}"

  ip_configuration {
    name                          = "${format("${var.computer_name_prefix}-%02d", 1 + count.index)}"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
  }

  tags = "${var.tags}"
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE VIRTUAL MACHINES TO RUN CONSUL
#---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine" "consul" {
  count                            = "${var.cluster_size}"
  name                             = "${format("${var.computer_name_prefix}-%02d", 1 + count.index)}"
  location                         = "${var.location}"
  resource_group_name              = "${data.azurerm_resource_group.consul.name}"
  availability_set_id              = "${azurerm_availability_set.consul.id}"
  network_interface_ids            = ["${azurerm_network_interface.consul.*.id[count.index]}"]
  vm_size                          = "${var.instance_size}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id = "${var.image_id}"
  }

  storage_os_disk {
    name              = "${format("${var.computer_name_prefix}-%02d-os-disk", 1 + count.index)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    os_type           = "Linux"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${format("${var.computer_name_prefix}-%02d", 1 + count.index)}"
    admin_username = "${var.admin_user_name}"
    admin_password = "${uuid()}"
    custom_data    = "${data.template_file.custom_data_consul.*.rendered[count.index]}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  lifecycle {
    ignore_changes = ["admin_password"]
  }

  tags = "${var.tags}"
}
