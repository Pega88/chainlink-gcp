
#todo RBAC
#todo x-namespace
#todo retainpolicy validation for pv

resource "kubernetes_service" "postgres" {
  metadata {
    name = "postgres"
    namespace = "chainlink"
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
}

resource "kubernetes_config_map" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "chainlink"
  }

  data = {
    "POSTGRES_DB" = "chainlink"
    "POSTGRES_USER" = "admin"
    "POSTGRES_PASSWORD" = "passw" 
  }
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name = "postgres"
    namespace = "chainlink"
  }

  spec {
    replicas = 2
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
          name              = "postgres"
          image             = "postgres:9.6.17"

          env_from {
            config_map_ref {
              name = "postgres"
            }
          }

          port {
            container_port = 5432
            name = "postgres"
          }

          volume_mount {
            name       = "postgresdb"
            mount_path = "/var/lib/postgresql/data"
            sub_path = "postgres"
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
}