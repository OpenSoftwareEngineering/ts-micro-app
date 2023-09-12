/******************************************
	VPC, subnets, routes and firewall configuration
******************************************/

locals {
  rules = [
    for f in var.firewall_rules : {
      name                    = f.name
      direction               = f.direction
      priority                = lookup(f, "priority", null)
      description             = lookup(f, "description", null)
      ranges                  = lookup(f, "ranges", null)
      source_tags             = lookup(f, "source_tags", null)
      source_service_accounts = lookup(f, "source_service_accounts", null)
      target_tags             = lookup(f, "target_tags", null)
      target_service_accounts = lookup(f, "target_service_accounts", null)
      allow                   = lookup(f, "allow", [])
      deny                    = lookup(f, "deny", [])
      log_config              = lookup(f, "log_config", null)
    }
  ]
}


module "network" {
  /*****
  VPC
  *****/
  source                                 = "../modules/network"
  network_name                           = var.network_name
  auto_create_subnetworks                = var.auto_create_subnetworks
  routing_mode                           = var.routing_mode
  project_id                             = var.project_id
  description                            = var.description
  shared_vpc_host                        = var.shared_vpc_host
  delete_default_internet_gateway_routes = var.delete_default_internet_gateway_routes
  mtu                                    = var.mtu

  /*****
  Subnet
  *****/
  subnets          = var.subnets
  secondary_ranges = var.secondary_ranges

  /*****
  Routes
  *****/
  routes = var.routes

  /*****
  Rules
  *****/
  rules = local.rules
}

/*****
  GKE Setup
*****/

module "gke" {
  source                     = "../modules/gke"
  project_id                 = var.project_id
  name                       = var.cluster_name
  region                     = var.region
  zones                      = var.zones
  network                    = var.network_name
  subnetwork                 = var.subnets[0].subnet_name
  ip_range_pods              = var.ip_range_pods
  ip_range_services          = var.ip_range_services
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = true

  node_pools = [
    {
      name               = var.node_pools_names
      machine_type       = var.machine_type
      node_locations     = var.node_locations
      min_count          = 1
      max_count          = 3
      local_ssd_count    = 0
      spot               = true
      disk_size_gb       = 100
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      auto_repair        = true
      auto_upgrade       = true
      service_account    = "project-service-account@${var.project_id}.iam.gserviceaccount.com"
      preemptible        = false
      initial_node_count = 1
    },
  ]
}