###################################
# Configure the OpenStack Provider
###################################
provider "openstack" {
  domain_name = var.domain_name
  tenant_id   = var.project_id
  user_name   = var.user_name
  password    = var.user_password
  auth_url    = "https://api.selvpc.ru/identity/v3"
  region      = var.region
}

resource "random_string" "random_name_1" {
  length  = 16
  special = false
}

###################################
# Flavor
###################################
resource "openstack_compute_flavor_v2" "flavor_1" {
  name      = "node.${var.project_id}-${random_string.random_name_1.result}"
  ram       = "2048"
  vcpus     = "1"
  disk      = "0"
  is_public = "false"
}

###################################
# Create SSH-key
###################################
resource "openstack_compute_keypair_v2" "terraform_key" {
  name       = "terraform_key-${random_string.random_name_1.result}"
  region     = var.region
  public_key = var.public_key
}


###################################
# Create Network and Subnet
###################################
data "openstack_networking_network_v2" "external_net" {
  name = "external-network"
}

resource "openstack_networking_router_v2" "router_1" {
  name                = "router_1"
  external_network_id = data.openstack_networking_network_v2.external_net.id
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = openstack_networking_router_v2.router_1.id
  subnet_id = openstack_networking_subnet_v2.subnet_1.id
}

resource "openstack_networking_network_v2" "network_1" {
  name = "network_1"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  network_id      = openstack_networking_network_v2.network_1.id
  name            = "192.168.0.0/24"
  cidr            = "192.168.0.0/24"
  dns_nameservers = ["188.93.16.19", "188.93.17.19"]
}





