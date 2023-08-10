/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
*/

locals {
  vpc_count_map = {
    "default"           = 0
    "new_multi_nic"     = 5
    "default_multi_nic" = 4
    "new_single_nic"    = 1
  }
  vpc_count = lookup(local.vpc_count_map, var.network_config, 0)
}

module "default_vpc" {
  source = "github.com/GoogleCloudPlatform/hpc-toolkit//modules/network/pre-existing-vpc//?ref=v1.17.0"
  count  = var.network_config == "default" || var.network_config == "default_multi_nic" ? 1 : 0

  project_id = var.project_id
  region     = var.region
}

resource "google_compute_network" "networks" {
  count                   = local.vpc_count
  name                    = "${var.resource_prefix}-net-${count.index}"
  project                 = var.project_id
  auto_create_subnetworks = false
  mtu                     = 8228
}

resource "google_compute_subnetwork" "subnets" {
  count         = local.vpc_count
  name          = "${var.resource_prefix}-sub-${count.index}"
  project       = var.project_id
  ip_cidr_range = "10.${count.index}.0.0/19"
  region        = var.region
  network       = google_compute_network.networks[count.index].self_link
}

resource "google_compute_firewall" "firewall-allow-tcp-udp-icmp" {
  count         = local.vpc_count
  name          = "${var.resource_prefix}-internal-${count.index}"
  project       = var.project_id
  description   = "allow traffic between nodes of this VPC"
  direction     = "INGRESS"
  network       = google_compute_network.networks[count.index].self_link
  source_ranges = ["10.0.0.0/8"]
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
}

// Assumes that an external IP is only created for vNIC 0
resource "google_compute_firewall" "firewall-allow-icmp" {
  count         = local.vpc_count > 0 ? 1 : 0
  name          = "${var.resource_prefix}-allow-ping-net-0"
  project       = var.project_id
  description   = "allow icmp ping access"
  direction     = "INGRESS"
  network       = google_compute_network.networks[0].self_link
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "firewall-allow-iap-ssh" {
  count       = local.vpc_count > 0 ? 1 : 0
  name        = "${var.resource_prefix}-allow-iap-ssh-net-0"
  project     = var.project_id
  description = "allow SSH access via Identity-Aware Proxy"
  direction   = "INGRESS"
  network     = google_compute_network.networks[0].self_link
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
}
