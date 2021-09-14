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
  host                   = format("https://%s", google_container_cluster.gke-cluster.endpoint)
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.gke-cluster.master_auth.0.cluster_ca_certificate)
}


resource "kubernetes_namespace" "chainlink" {
  metadata {
    name = "chainlink"
  }
  depends_on = [
    /* Normally the endpoint is populated as soon as it is known to Terraform.
      * However, the cluster may not be in a usable state yet.  Therefore any
      * resources dependent on the cluster being up will fail to deploy.  With
      * this explicit dependency, dependent resources can wait for the cluster
      * to be up.
      */
    google_container_cluster.gke-cluster,
    google_container_node_pool.main_nodes
  ]

}

resource "kubernetes_config_map" "chainlink-env" {
  metadata {
    name      = "chainlink-env"
    namespace = kubernetes_namespace.chainlink.metadata.0.name
  }

  data = {
    #"env" = file("config/.env")
    ROOT                       = "/chainlink"
    LOG_LEVEL                  = "debug"
    ETH_CHAIN_ID               = 3
    MIN_OUTGOING_CONFIRMATIONS = 2
    LINK_CONTRACT_ADDRESS      = "0x20fe562d797a42dcb3399062ae9546cd06f63280"
    CHAINLINK_TLS_PORT         = 0
    SECURE_COOKIES             = false
    GAS_UPDATER_ENABLED        = true
    ALLOW_ORIGINS              = "*"
    DATABASE_URL               = format("postgresql://%s:%s@postgres:5432/chainlink?sslmode=disable", var.postgres_username, random_password.postgres-password.result)
    DATABASE_TIMEOUT           = 0
    ETH_URL                    = "wss://ropsten.infura.io/ws/v3/a13a37a22d784e39926def7c35e9e415"
  }
  #BRIT: Added dependency on namespace creation.
  depends_on = [kubernetes_namespace.chainlink]
}


resource "random_password" "api-password" {
  length  = 16
  special = false
}

resource "random_password" "wallet-password" {
  length  = 16
  special = false
}

resource "kubernetes_secret" "api-credentials" {
  metadata {
    name      = "api-credentials"
    namespace = kubernetes_namespace.chainlink.metadata.0.name
  }

  data = {
    api = format("%s\n%s", var.node_username, random_password.api-password.result)
  }
#BRIT: Added dependency on namespace creation.
  depends_on = [
  	kubernetes_namespace.chainlink
  ]
}

resource "kubernetes_secret" "password-credentials" {
  metadata {
    name      = "password-credentials"
    namespace = kubernetes_namespace.chainlink.metadata.0.name
  }

  data = {
    password = random_password.wallet-password.result
  }
  #BRIT: Added dependency on namespace creation.
  depends_on = [
  	kubernetes_namespace.chainlink
  ]
}


#todo env vars to populate $POSTGRES_USER:$POSTGRES_PASS@$POSTGRES_HOST:$POSTGRES_PORT/db
#getting it from resource "kubernetes_config_map" "postgres"
resource "kubernetes_deployment" "chainlink-node" {
  metadata {
    name      = "chainlink"
    namespace = kubernetes_namespace.chainlink.metadata.0.name
    labels = {
      app = "chainlink-node"
    }
  }

  spec {
    replicas = 2

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
          image = "smartcontract/chainlink:0.9.10" #BRIT: Updated to the highest v9 chainlink release, v10 seems to want to upgrade from here.
          name  = "chainlink-node"
          port {
            container_port = 6688
          }
          args = ["local", "n", "-p", "/chainlink/.password", "-a", "/chainlink/.api"]

          env_from {
            config_map_ref {
              name = "chainlink-env"
            }
          }

          volume_mount {
            name       = "api-volume"
            sub_path   = "api"
            mount_path = "/chainlink/.api"
          }

          volume_mount {
            name       = "password-volume"
            sub_path   = "password"
            mount_path = "/chainlink/.password"
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

  #BRIT: Added dependency on Main-Nodes & PostgreDB creation.
  depends_on = [
  	google_container_node_pool.main_nodes, 
  	kubernetes_stateful_set.postgres
  ]
}

resource "kubernetes_service" "chainlink_service" {
  metadata {
    name      = "chainlink-node"
    namespace = kubernetes_namespace.chainlink.metadata.0.name
  }
  spec {
    selector = {
      app = "chainlink-node"
    }
    type = "NodePort"
    port {
      port = 6688
    }
  }
  #BRIT: Added dependency on namespace creation.
  depends_on = [
  	kubernetes_namespace.chainlink
  ]
}

resource "google_compute_global_address" "chainlink-node" {
  name = "chainlink-node"
}

resource "kubernetes_ingress" "chainlink_ingress" {
  metadata {
    name      = "chainlink-ingress"
    namespace = kubernetes_namespace.chainlink.metadata.0.name
    annotations = {
      #"ingress.gcp.kubernetes.io/pre-shared-cert" = var.ssl_cert_name
      #"kubernetes.io/ingress.allow-http"=false
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.chainlink-node.name
    }
  }
  spec {
    backend {
      service_name = "chainlink-node"
      service_port = 6688
    }
  }
  #BRIT: Added dependency on namespace creation.
  depends_on = [
  	kubernetes_namespace.chainlink
  ]
}

output "chainlink_ip" {
  description = "Global IPv4 address for the Load Balancer serving the Chainlink Node"
  value       = google_compute_global_address.chainlink-node.address
}
