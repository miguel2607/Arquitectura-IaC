output "red_driver" {
  value = data.docker_network.bridge.driver
}

output "urls" {
  value = { for k, m in module.sitio : m.nombre => m.url }
}
