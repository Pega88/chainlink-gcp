/******************************************
  Retrieve authentication token
 *****************************************/
data "google_client_config" "default" {
  provider = google
}


/******************************************
  Configure provider
 *****************************************/
provider "kubernetes" {
  load_config_file       = false
  host                   = "https://${google_container_cluster.gke-cluster.endpoint}"
  token                  = "${data.google_client_config.default.access_token}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.gke-cluster.master_auth.0.cluster_ca_certificate)}"
}


resource "kubernetes_namespace" "chainlink" {
  metadata {
    name = "chainlink"
  }
}

resource "kubernetes_config_map" "env-vars" {
  metadata {
    name      = "env-vars"
    namespace = "chainlink"
  }

  data = {
    ".env" = "${file("config/.env")}"
  }
}

#   data = {
#     "helm-values.yaml"          = "${file("${path.module}/spinnaker/config/helm-values.yaml")}"
#     "helm-values-template.yaml" = "${file("${path.module}/spinnaker/config/helm-values-template.yaml")}"
#   }
# }
# resource "kubernetes_secret" "spinnaker-gcr-credentials" {
#   metadata {
#     name      = "spinnaker-gcr"
#     namespace = "${kubernetes_namespace.devops.metadata.0.name}"
#   }
#   data = {
#     gcr = "${base64decode(google_service_account_key.spin_key.private_key)}"
#   }
# }

# resource "kubernetes_job" "install_devops" {
#   metadata {
#     name      = "install-devops"
#     namespace = "${kubernetes_namespace.devops.metadata.0.name}"
#   }
#   spec {
#     template {
#       metadata {}
#       spec {
#         container {
#           name  = "devops-mgmt"
#           image = "eu.gcr.io/niels-nessie-mgmt-3/spinnaker-mgmt:0.0.4.17"
#           volume_mount {
#             name       = "devops-volume"
#             mount_path = "/mnt/devops"
#           }
#           volume_mount {
#             name       = "helm-spinnaker-config"
#             mount_path = "/mnt/devops/spinnaker-config"
#           }
#           volume_mount {
#             name       = "spinnaker-sa-credentials"
#             mount_path = "/mnt/devops/key.json"
#           }
#         }
#         volume {
#           name = "devops-volume"
#           persistent_volume_claim {
#             claim_name = "devops-state"
#           }
#         }
#         volume {
#           name = "spinnaker-sa-credentials"
#           secret {
#             secret_name = "spinnaker-credentials"
#           }
#         }
#         volume {
#           name = "helm-spinnaker-config"
#           config_map {
#             name = "${kubernetes_config_map.spinnaker_helm.metadata.0.name}"
#           }
#         }
#         restart_policy                  = "Never"
#         service_account_name            = "devops"
#         automount_service_account_token = true
#       }
#     }
#     #backoff_limit = 4
#   }
#   depends_on = [
#     google_project_iam_member.spin_create_gcs
#   ]
# }
