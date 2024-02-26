# Only rough Terraform manifest file

variable "Martinus First Project" {
  description = "ID projektu v GCP"
}

variable "region" {
  description = "Region, ve kterém budou vytvořeny zdroje"
  default     = "us-central1"
}

variable "docker_image" {
  description = "image dockeru pro nasazení na virtuální počítače"
  default     = "nginxinc/nginx-unprivileged:1.19.1-alpine"
}

variable "dev_instance_count" {
  description = "Počet instancí pro DEV prostředí"
  default     = 2
}

variable "prod_instance_count" {
  description = "Počet instancí pro PROD prostředí"
  default     = 3
}

provider "google" {
  credentials = file("Cesta_k_souboru_se_service_account_key")
  project     = var.project_id
  region      = var.region
}

resource "google_compute_instance_template" "instance_template" {
  name = "instance-template"

  disk {
    image = var.docker_image
  }

  network_interface {
    network = "default"
  }

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    docker run -d -p 80:80 ${var.docker_image}
  SCRIPT
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name = "instance-group-manager"
  base_instance_name = "instance"
  instance_template = google_compute_instance_template.instance_template.self_link
  target_size = var.dev_instance_count + var.prod_instance_count
}

resource "google_compute_http_health_check" "http_health_check" {
  name = "http-health-check"
  port = 80
  request_path = "/"
}

resource "google_compute_backend_service" "backend_service" {
  name = "backend-service"
  port_name = "http"
  protocol = "HTTP"
  backend {
    group = google_compute_instance_group_manager.instance_group_manager.self_link
  }
  health_checks = [google_compute_http_health_check.http_health_check.self_link]
}

resource "google_compute_url_map" "url_map" {
  name = "url-map"
  default_route_action {
    backend_service = google_compute_backend_service.backend_service.self_link
  }
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name       = "forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.self_link
  port_range = "80"
}

resource "google_compute_target_pool" "target_pool" {
  name = "target-pool"
  instances = google_compute_instance_group_manager.instance_group_manager.instances[*].self_link
}

resource "google_compute_instance_group_manager" "prod_instance_group_manager" {
  name = "prod-instance-group-manager"
  base_instance_name = "prod-instance"
  instance_template = google_compute_instance_template.instance_template.self_link
  target_size = var.prod_instance_count
}

resource "google_compute_target_pool" "prod_target_pool" {
  name = "prod-target-pool"
  instances = google_compute_instance_group_manager.prod_instance_group_manager.instances[*].self_link
}

resource "google_compute_backend_service" "prod_backend_service" {
  name = "prod-backend-service"
  port_name = "http"
  protocol = "HTTP"
  backend {
    group = google_compute_instance_group_manager.prod_instance_group_manager.self_link
  }
  health_checks = [google_compute_http_health_check.http_health_check.self_link]
}

resource "google_compute_path_matcher" "path_matcher" {
  name    = "path-matcher"
  default_route_action {
    backend_service = google_compute_backend_service.prod_backend_service.self_link
  }
  default_service = google_compute_backend_service.backend_service.self_link
}

resource "google_compute_url_map" "prod_url_map" {
  name = "prod-url-map"
  path_matchers = [google_compute_path_matcher.path_matcher.self_link]
}