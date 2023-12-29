output "prod_dns_name" {
  value       = module.webserver_cluster.dns_name
  description = "DNS of LB"
}