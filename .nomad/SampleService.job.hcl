job "SampleService" {
  datacenters = ["dc1"]
  type        = "service"

  meta {
    version  = "[[semver]]"
    run_uuid = "${uuidv4()}"
  }

  reschedule {
    delay          = "30s"
    delay_function = "constant"
    unlimited      = true
  }

  update {
    max_parallel      = 1
    min_healthy_time  = "10s"
    healthy_deadline  = "5m"
    progress_deadline = "10m"
    auto_revert       = true
    canary            = 0
    stagger           = "30s"
  }

  group "SampleService" {

    count = 3

    restart {
      interval = "10m"
      attempts = 2
      delay    = "15s"
      mode     = "fail"
    }

    spread {
      attribute = "${node.unique.id}"
      weight    = 100
    }

    network {
      port "httpSampleService" {}
    }

    task "SampleService" {
      driver = "raw_exec"

      artifact {
        source = "http://pdcvw-nomfil01:8765/SampleService_[[semver]].zip"
      }

      config {
        command = "SampleService.exe"
        args = [
          "--urls",
          "http://*:${NOMAD_PORT_httpSampleService}",
        ]
      }

      env {
        ASPNETCORE_ENVIRONMENT = "[[environment_name]]"
      }

      service {
        name = "SampleService"
        port = "httpSampleService"

        tags = [
          "platform-team",
          "traefik.enable=true",
          "traefik.http.routers.SampleService.rule=PathPrefix(`/sample`)",
          "traefik.http.routers.SampleService.middlewares=SampleService-stripprefix",
          "traefik.http.middlewares.SampleService-stripprefix.stripprefix.prefixes=/sample",
          "[[semver]]"
        ]

        check {
          type     = "http"
          path     = "/health"
          interval = "2s"
          timeout  = "200s"
        }

        check_restart {
          limit           = 3
          grace           = "10s"
          ignore_warnings = false
        }
      }

      resources {
        cpu    = 50  # MHz
        memory = 256 # MB
      }

    }
  }
}
