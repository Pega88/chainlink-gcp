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