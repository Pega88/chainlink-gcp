# TODO liveness & readiness probes
# TODO enable SSL on postgres

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

resource "kubernetes_config_map" "chainlink-env" {
  metadata {
    name      = "chainlink-env"
    namespace = "chainlink"
  }

  data = {
    #"env" = "${file("config/.env")}"
    ROOT = "/chainlink"
    LOG_LEVEL = "debug"
    ETH_CHAIN_ID = 3
    MIN_OUTGOING_CONFIRMATIONS = 2
    LINK_CONTRACT_ADDRESS = "0x20fe562d797a42dcb3399062ae9546cd06f63280"
    CHAINLINK_TLS_PORT = 0
    SECURE_COOKIES = false
    ORACLE_CONTRACT_ADDRESS = "0x9f37f5f695cc16bebb1b227502809ad0fb117e08"
    ALLOW_ORIGINS = "*"
    MINIMUM_CONTRACT_PAYMENT = 100
    DATABASE_URL = "postgresql://${var.postgres_username}:${random_password.postgres-password.result}@postgres:5432/chainlink?sslmode=disable"
    DATABASE_TIMEOUT = 0
    ETH_URL = "wss://ropsten-rpc.linkpool.io/ws"
  }
}


resource "random_password" "api-password" {
  length  = 16
  special = false
}

resource "random_password" "wallet-password" {
  length  = 16
  special = false
}

output "api-credentials" {
  value = "${random_password.api-password.result}"
  #sensitive   = true #to hide output
}

output "wallet-credentials" {
  value = "${random_password.wallet-password.result}"
  #sensitive   = true #to hide output
}

resource "kubernetes_secret" "api-credentials" {
  metadata {
    name      = "api-credentials"
    namespace = "chainlink"
  }

  data = {
    api = "${var.node_username}\n${random_password.api-password.result}"

  }
}

resource "kubernetes_secret" "password-credentials" {
  metadata {
    name      = "password-credentials"
    namespace = "chainlink"
  }

  data = {
    password = "${random_password.wallet-password.result}"
  }
}


#todo env vars to populate $POSTGRES_USER:$POSTGRES_PASS@$POSTGRES_HOST:$POSTGRES_PORT/db
#getting it from resource "kubernetes_config_map" "postgres"
resource "kubernetes_deployment" "chainlink-node" {
  metadata {
    name = "chainlink"
    namespace = "chainlink"
    labels = {
      app = "chainlink-node"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "chainlink-node"
      }
    }

    template {
      metadata {
        labels = {
          app = "chainlink-node"
        }
      }
      spec {
        container {
          image = "smartcontract/chainlink:0.7.5"
          name  = "chainlink-node"
          port {
            container_port = 6688
          }
          #command = ["/bin/bash", "-c", "echo $(ETH_URL)"]
          args = ["local", "n", "-p",  "/chainlink/.password", "-a", "/chainlink/.api"]

          #needed for explicit data field ref in configmap
          env_from {
            config_map_ref {
              name = "chainlink-env"
            }
          }
          volume_mount {
            name        = "api-volume"
            sub_path    = "api"
            mount_path  = "/chainlink/.api"
          }
          volume_mount {
            name        = "password-volume"
            sub_path    = "password"
            mount_path  = "/chainlink/.password"
          }
        }
        volume {
          name = "api-volume"
          secret {
            secret_name = "api-credentials" 
          }
        }
        volume {
          name = "password-volume"
          secret {
            secret_name = "password-credentials" 
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "chainlink_service" {
  metadata {
    name = "chainlink-node"
    namespace = "chainlink"
  }
  spec {
    selector = {
      app = "chainlink-node"
    }
    type = "NodePort"
    port {
      port        = 6688
    }
  }
}

resource "google_compute_global_address" "chainlink-node" {
  name = "chainlink-node"
}

resource "kubernetes_ingress" "chainlink_ingress" {
  metadata {
    name = "chainlink-ingress"
    namespace = "chainlink"
    annotations {
      #"ingress.gcp.kubernetes.io/pre-shared-cert" = "${ var.ssl_cert_name }"
      #"kubernetes.io/ingress.allow-http" = "false"
      "kubernetes.io/ingress.global-static-ip-name" = "${google_compute_global_address.chainlink-node.name}"
    }
  }
  spec {
    backend {
      service_name = "chainlink-node"
      service_port = 6688
    }
  }
}

output "chainlink_node_ip" {
  description = "Global IPv4 address for the Load Balancer serving the Chainlink Node"
  value       = kubernetes_ingress.chainlink_ingress.load_balancer_ingress
}
