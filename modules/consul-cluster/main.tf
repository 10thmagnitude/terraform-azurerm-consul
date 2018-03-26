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

data "template_file" "custom_data" {
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
    custom_data    = "${data.template_file.custom_data.*.rendered[count.index]}"
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

#---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP AND RULES FOR SSH
#---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_security_group" "consul" {
  name                = "${var.cluster_prefix}"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.consul.name}"

  tags = "${var.tags}"
}

resource "azurerm_network_security_rule" "ssh" {
  count = "${length(var.allowed_ssh_cidr_blocks)}"

  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "22"
  direction                   = "Inbound"
  name                        = "SSH${count.index}"
  network_security_group_name = "${azurerm_network_security_group.consul.name}"
  priority                    = "${100 + count.index}"
  protocol                    = "Tcp"
  resource_group_name         = "${data.azurerm_resource_group.consul.name}"
  source_address_prefix       = "${element(var.allowed_ssh_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}

#---------------------------------------------------------------------------------------------------------------------
# THE CONSUL-SPECIFIC INBOUND/OUTBOUND RULES COME FROM THE CONSUL-SECURITY-GROUP-RULES MODULE
#---------------------------------------------------------------------------------------------------------------------

module "security_group_rules" {
  source = "../consul-security-group-rules"

  security_group_name         = "${azurerm_network_security_group.consul.name}"
  resource_group_name         = "${data.azurerm_resource_group.consul.name}"
  allowed_inbound_cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  server_rpc_port = "${var.server_rpc_port}"
  cli_rpc_port    = "${var.cli_rpc_port}"
  serf_lan_port   = "${var.serf_lan_port}"
  serf_wan_port   = "${var.serf_wan_port}"
  http_api_port   = "${var.http_api_port}"
  dns_port        = "${var.dns_port}"
}
