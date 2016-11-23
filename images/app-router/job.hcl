job "app-router" {
  region = "us"
  datacenters = ["us-east-1"]
  type = "service"

  update {
    stagger      = "30s"
    max_parallel = 1
  }

  constraint {
    operator  = "distinct_hosts"
    value     = "true"
  }
  
  group "servers" {
    count = 1

    task "nginx" {
      driver = "docker"

      config {
        image = "jasonpincin/test-router"
        port_map = {
            http = 80
        }
      }

      service {
        port = "http"

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }

      env {
        "CONSUL_HTTP_IP" = "${DOCKER_HOST_IP}"
      }

      resources {
        cpu    = 500 # MHz
        memory = 128 # MB

        network {
          mbits = 100

          port "http" {
            static = 80
          }
        }
      }
    }
  }
}
