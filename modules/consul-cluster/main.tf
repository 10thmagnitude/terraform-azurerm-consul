terraform {
  required_version = ">= 0.10.0"
}

data "template_file" "cfg" {
  count    = "${var.cluster_size}"
  template = "${file("${path.module}/files/consul-config")} "

  vars {
    node_ip_address = "${azurerm_network_interface.consul.*.private_ip_address[count.index]}"
    cluster_size    = "${var.cluster_size}"
    datacenter      = "${var.location}"
    node_name       = "${format("${var.computer_name_prefix}-%02d", 1 + count.index)}"
    join_ip_address = "${count.index > 0 ? azurerm_network_interface.consul.0.private_ip_address : ""}"
    is_node_server  = "${var.create_as_server == "1" ? true : false }"
    is_ui_enabled   = "${(var.create_as_server && count.index == 0) ? true : false }"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE NETWORK INTERFACES TO RUN CONSUL
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_interface" "consul" {
  count               = "${var.cluster_size}"
  name                = "${format("${var.computer_name_prefix}-%02d", 1 + count.index)}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "${format("${var.computer_name_prefix}-%02d", 1 + count.index)}"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE VIRTUAL MACHINES TO RUN CONSUL
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_virtual_machine" "consul" {
  count                            = "${var.cluster_size}"
  name                             = "${format("${var.computer_name_prefix}-%02d", 1 + count.index)}"
  location                         = "${var.location}"
  resource_group_name              = "${var.resource_group_name}"
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

    #This password is unimportant as it is disabled below in the os_profile_linux_config
    admin_password = "Passwword1234"
    custom_data    = "${var.custom_data}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  provisioner "file" {
    source      = "${path.module}/files/consul-service"
    destination = "/tmp/consul.service.moveme"
  }

  provisioner "file" {
    content     = "${file("${path.module}/files/consul-config-ui")}"
    destination = "/tmp/ui.json.moveme"
  }

  provisioner "file" {
    content     = "${data.template_file.cfg.*.rendered[count.index]}"
    destination = "/tmp/config.json.moveme"
  }

  provisioner "file" {
    content     = "${file("${path.module}/files/consul-run")}"
    destination = "/tmp/consul-run.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/consul-run.sh",
      "sudo /bin/bash -c /tmp/consul-run.sh",
    ]
  }

  connection {
    user         = "${var.admin_user_name}"
    host         = "${azurerm_network_interface.consul.*.private_ip_address[count.index]}"
    private_key  = "${var.private_key_path}"
    bastion_host = "${var.bastion_host_address}"
  }
}

#---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP AND RULES FOR SSH
# ---------------------------------------------------------------------------------------------------------------------

resource "azurerm_network_security_group" "consul" {
  name                = "${var.cluster_prefix}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
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
  resource_group_name         = "${var.resource_group_name}"
  source_address_prefix       = "${element(var.allowed_ssh_cidr_blocks, count.index)}"
  source_port_range           = "1024-65535"
}

# ---------------------------------------------------------------------------------------------------------------------
# THE CONSUL-SPECIFIC INBOUND/OUTBOUND RULES COME FROM THE CONSUL-SECURITY-GROUP-RULES MODULE
# ---------------------------------------------------------------------------------------------------------------------

module "security_group_rules" {
  source = "../consul-security-group-rules"

  security_group_name         = "${azurerm_network_security_group.consul.name}"
  resource_group_name         = "${var.resource_group_name}"
  allowed_inbound_cidr_blocks = ["${var.allowed_inbound_cidr_blocks}"]

  server_rpc_port = "${var.server_rpc_port}"
  cli_rpc_port    = "${var.cli_rpc_port}"
  serf_lan_port   = "${var.serf_lan_port}"
  serf_wan_port   = "${var.serf_wan_port}"
  http_api_port   = "${var.http_api_port}"
  dns_port        = "${var.dns_port}"
}
