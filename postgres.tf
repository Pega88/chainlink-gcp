
#todo RBAC
#todo x-namespace
#todo retainpolicy validation for pv
#todo replication statefulset

resource "random_password" "postgres-password" {
  length  = 16
  special = false
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.chainlink.metadata.0.name
  }
  spec {
    selector = {
      app = "postgres"
    }
    port {
      port        = 5432
      target_port = 5432
    }
  }
  depends_on = [
    kubernetes_stateful_set.postgres
  ]
}

resource "kubernetes_config_map" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.chainlink.metadata.0.name
  }

  data = {
    "POSTGRES_DB"       = "chainlink"
    "POSTGRES_USER"     = var.postgres_username
    "POSTGRES_PASSWORD" = random_password.postgres-password.result
  }
 #BRIT: Added dependency on namespace creation.
  depends_on = [
  	kubernetes_namespace.chainlink
  ]
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = "postgres"
    namespace = kubernetes_namespace.chainlink.metadata.0.name
  }

  spec {
    replicas     = 1 #multiple replicas here on master would create multiple volumes
    service_name = "postgres"
    selector {
      match_labels = {
        app = "postgres"
      }
    }
    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres:13.3" #BRIT: Updated to highest current release from 9.6.17

          env_from {
            config_map_ref {
              name = "postgres"
            }
          }

          port {
            container_port = 5432
            name           = "postgres"
          }

          volume_mount {
            name       = "postgresdb"
            mount_path = "/var/lib/postgresql/data"
            sub_path   = "postgres"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "postgresdb"
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = "standard"

        resources {
          requests = {
            storage = "5Gi"
          }
        }
      }
    }
  }
  #BRIT: Added dependency on main node creation & a config_map.
  depends_on = [
  	google_container_node_pool.main_nodes, kubernetes_config_map.postgres
  ]
}