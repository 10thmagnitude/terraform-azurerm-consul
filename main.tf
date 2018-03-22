# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY A CONSUL CLUSTER IN AZURE
# These templates show an example of how to use the consul-cluster module to deploy Consul in Azure. We deploy two
# Scale Sets: one with Consul server nodes and one with Consul client nodes. Note that these templates assume
# that the Custom Image you provide via the image_id input variable is built from the
# examples/consul-image/consul.json Packer template.
# ---------------------------------------------------------------------------------------------------------------------

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}

terraform {
  required_version = ">= 0.10.0"
}

resource "azurerm_resource_group" "consul" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

data "azurerm_image" "consul" {
  name_regex          = "${var.image_regex}"
  resource_group_name = "${var.image_resource_group_name}"
  sort_descending     = true
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE NECESSARY NETWORK RESOURCES FOR THE EXAMPLE
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "consul" {
  name                = "consulvn"
  address_space       = ["${var.test_address_space}"]
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.consul.name}"
}

resource "azurerm_subnet" "consul" {
  name                 = "consulsubnet"
  resource_group_name  = "${azurerm_resource_group.consul.name}"
  virtual_network_name = "${azurerm_virtual_network.consul.name}"
  address_prefix       = "${var.test_subnet_address}"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE CONSUL SERVER NODES
# ---------------------------------------------------------------------------------------------------------------------

module "consul_servers" {
  # When using these modules in your own templates, you will need to use a Git URL with a ref attribute that pins you
  # to a specific version of the modules, such as the following example:
  # source = "git::git@github.com:hashicorp/terraform-azurerm-consul.git//modules/consul-cluster?ref=v0.0.1"
  source = "./modules/consul-cluster"

  cluster_prefix = "${var.cluster_name}"
  cluster_size   = "${var.num_servers}"
  key_data       = "${var.key_data}"

  # To make testing easier, we allow Consul and SSH requests from any IP address here but in a production
  # deployment, we strongly recommend you limit this to the IP address ranges of known, trusted servers inside your VPC.
  allowed_ssh_cidr_blocks = "${var.allowed_ssh_cidr_blocks}"

  allowed_inbound_cidr_blocks = "${var.allowed_inbound_cidr_blocks}"

  resource_group_name = "${azurerm_resource_group.consul.name}"

  location              = "${var.location}"
  instance_size         = "${var.instance_size}"
  admin_user_name       = "${var.admin_user_name}"
  bastion_host_address  = "${data.azurerm_public_ip.bastion.ip_address}"
  private_key_path      = "${file(var.private_key_path)}"
  image_id              = "${data.azurerm_image.consul.id}"
  subnet_id             = "${azurerm_subnet.consul.id}"
  gossip_encryption_key = "${var.gossip_encryption_key}"
  consul_install_path   = "/etc/consul.d/"
  tls_key_file_path     = "/etc/consul.d/tls/consul.key.pem"
  tls_cert_file_path    = "/etc/consul.d/tls/consul.crt.pem"
  tls_ca_file_path      = "/etc/consul.d/tls/ca.crt.pem"
}

# ---------------------------------------------------------------------------------------------------------------------
# BASTION FOR TESTING
# ---------------------------------------------------------------------------------------------------------------------
data "azurerm_public_ip" "bastion" {
  name                = "${azurerm_public_ip.bastion.name}"
  resource_group_name = "${azurerm_resource_group.consul.name}"
  depends_on          = ["azurerm_public_ip.bastion"]
}

resource "azurerm_public_ip" "bastion" {
  name                         = "bastion-pip"
  location                     = "${azurerm_resource_group.consul.location}"
  resource_group_name          = "${azurerm_resource_group.consul.name}"
  public_ip_address_allocation = "static"
  idle_timeout_in_minutes      = 30
}

resource "azurerm_network_interface" "bastion" {
  name                = "bastion-nic"
  location            = "${azurerm_resource_group.consul.location}"
  resource_group_name = "${azurerm_resource_group.consul.name}"

  ip_configuration {
    name                          = "ip-cfg"
    subnet_id                     = "${azurerm_subnet.consul.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.bastion.id}"
  }
}

resource "azurerm_virtual_machine" "bastion" {
  name                          = "bastion-01"
  location                      = "${azurerm_resource_group.consul.location}"
  resource_group_name           = "${azurerm_resource_group.consul.name}"
  network_interface_ids         = ["${azurerm_network_interface.bastion.id}"]
  vm_size                       = "Standard_A1_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    id = "${data.azurerm_image.consul.id}"
  }

  storage_os_disk {
    name              = "bastion-01-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "bastion-01"
    admin_username = "${var.admin_user_name}"
    admin_password = "${uuid()}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/${var.admin_user_name}/.ssh/authorized_keys"
      key_data = "${var.key_data}"
    }
  }

  lifecycle {
    ignore_changes = ["admin_password"]
  }
}
