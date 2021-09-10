terraform {
  required_version = ">= 1.0.6"
}
provider "google" {
  credentials = file("key.json")
  project     = var.project_name
  region      = var.gcp_region
  zone        = var.gcp_zone
}

# remote bucket config for better maintainability
# terraform {
#   backend "gcs" {
#     bucket  = "tf-chainlink-bucket"
#     prefix  = "terraform/state"
#     credentials = "key.json"
#   }
# }


#Google APIs
resource "google_project_service" "compute_api" {
  service  = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}
resource "google_project_service" "container_api" {
  service  = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
  depends_on = [
    google_project_service.compute_api
  ]
}
resource "google_project_service" "cloudresourcemanager_api" {
  service  = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
  depends_on = [
    google_project_service.container_api
  ]
}