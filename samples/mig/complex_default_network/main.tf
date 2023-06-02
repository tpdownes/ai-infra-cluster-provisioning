variable "project_id" {}
variable "resource_prefix" {}
variable "target_size" {}
variable "zone" {}
variable "machine_type" {}
variable "enable_ray" {}
variable "filestore_new" {}
variable "gcsfuse_existing" {}
variable "labels" {}
variable "machine_image" {}
variable "startup_script" {}
module "complex-mig1" {
  source           = "github.com/GoogleCloudPlatform/ai-infra-cluster-provisioning//terraform/modules/cluster/mig"
  project_id       = var.project_id
  resource_prefix  = var.resource_prefix
  target_size      = var.target_size
  zone             = var.zone
  machine_type     = var.machine_type
  enable_ray       = var.enable_ray
  filestore_new    = var.filestore_new
  gcsfuse_existing = var.gcsfuse_existing
  labels           = var.labels
  machine_image    = var.machine_image
  startup_script   = var.startup_script
}