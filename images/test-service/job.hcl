job "test-service" {
  region = "us"
  datacenters = ["us-east-1"]
  type = "service"

  update {
    stagger      = "30s"
    max_parallel = 1
  }
  
  group "webs" {
    count = 6

    task "frontend" {
      driver = "docker"

      config {
        image = "jasonpincin/test-service"
        port_map = {
            http = 5000
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
        "PORT" = "5000"
      }

      resources {
        cpu    = 500 # MHz
        memory = 128 # MB

        network {
          mbits = 100

          port "http" {}
        }
      }
    }
  }
}
