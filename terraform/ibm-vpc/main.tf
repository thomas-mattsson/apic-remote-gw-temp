provider ibm {
  ibmcloud_api_key      = var.ibmcloud_api_key
  region                = var.ibmcloud_region
  ibmcloud_timeout      = 60
}

resource "ibm_resource_group" "resourceGroup" {
  name = var.name
}

resource "ibm_is_vpc" "vpc" {
  name           = "${var.name}-vpc"
  resource_group = ibm_resource_group.resourceGroup.id
}

resource "ibm_is_vpc_routing_table" "routingTable" {
  name = "${var.name}-routing-table"
  vpc  =  ibm_is_vpc.vpc.id
}

resource ibm_is_vpc_address_prefix subnet_prefix {
  name     = "${var.name}-subnet-a-prefix"
  zone     = var.ibmcloud_zone
  vpc      = ibm_is_vpc.vpc.id
  cidr     = var.ibmcloud_subnet_cidr
}

resource ibm_is_public_gateway gateway {
  name           = "${var.name}-public-gateway"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = ibm_resource_group.resourceGroup.id
  zone           = var.ibmcloud_zone
}

resource "ibm_is_subnet" "subnet" {
  name            = "${var.name}-subnet-a"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.ibmcloud_zone
  ipv4_cidr_block = ibm_is_vpc_address_prefix.subnet_prefix.cidr
  routing_table   = ibm_is_vpc_routing_table.routingTable.routing_table
  public_gateway  = ibm_is_public_gateway.gateway.id
}

resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.name}-cos-instance"
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  resource_group_id = ibm_resource_group.resourceGroup.id
}

resource "ibm_container_vpc_cluster" "cluster" {
  name              = "${var.name}-cluster"
  vpc_id            = ibm_is_vpc.vpc.id
  kube_version      = var.kube_version
  flavor            = var.machine_flavor
  worker_count      = var.worker_count
  resource_group_id = ibm_resource_group.resourceGroup.id
  cos_instance_crn  = ibm_resource_instance.cos_instance.id
  zones {
      subnet_id     = ibm_is_subnet.subnet.id
      name          = ibm_is_subnet.subnet.zone
  }
}

# Give some time for access rights to cluster to be set up
resource "time_sleep" "wait" {
  depends_on = [
    ibm_container_vpc_cluster.cluster
  ]

  create_duration = "300s"
}

data "ibm_container_cluster_config" "cluster_config" {
  depends_on = [
    time_sleep.wait
  ]
  cluster_name_id = ibm_container_vpc_cluster.cluster.id
  config_dir      = "${path.root}/.terraform"
}

locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = ibm_container_vpc_cluster.cluster.name
      cluster = {
        certificate-authority-data = base64encode(data.ibm_container_cluster_config.cluster_config.ca_certificate)
        server                     = data.ibm_container_cluster_config.cluster_config.host
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = ibm_container_vpc_cluster.cluster.name
        user    = "terraform"
      }
    }]
    users = [{
      name = "terraform"
      user = {
        token = data.ibm_container_cluster_config.cluster_config.token
      }
    }]
  })
}

output "cluster-name" {
  value = ibm_container_vpc_cluster.cluster.name
}

output "cluster-id" {
  value = ibm_container_vpc_cluster.cluster.id
}

output "kubeconfig" {
  value = local.kubeconfig
  sensitive = true
}

output "ingress-subdomain" {
  value = ibm_container_vpc_cluster.cluster.ingress_hostname
}