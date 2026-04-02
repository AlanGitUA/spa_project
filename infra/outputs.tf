# ============================================================
# Outputs - Innovatech Chile POC
# ============================================================

# --- Red ---
output "vpc_id" {
  description = "ID de la VPC Innovatech"
  value       = aws_vpc.innovatech_vpc.id
}

output "public_subnet_id" {
  description = "ID de la subred publica (Frontend)"
  value       = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "ID de la subred privada (Backend + Data)"
  value       = aws_subnet.private_subnet.id
}

# --- Frontend ---
output "frontend_public_ip" {
  description = "IP publica del Frontend (acceso desde Internet)"
  value       = aws_instance.frontend.public_ip
}

output "frontend_private_ip" {
  description = "IP privada del Frontend"
  value       = aws_instance.frontend.private_ip
}

output "frontend_instance_id" {
  description = "Instance ID del Frontend (para Session Manager)"
  value       = aws_instance.frontend.id
}

# --- Backend ---
output "backend_private_ip" {
  description = "IP privada del Backend (acceso solo desde Frontend)"
  value       = aws_instance.backend.private_ip
}

output "backend_instance_id" {
  description = "Instance ID del Backend (para Session Manager)"
  value       = aws_instance.backend.id
}

# --- Data ---
output "data_private_ip" {
  description = "IP privada de Data (acceso solo desde Backend)"
  value       = aws_instance.data.private_ip
}

output "data_instance_id" {
  description = "Instance ID de Data (para Session Manager)"
  value       = aws_instance.data.id
}

# --- Acceso ---
output "frontend_url" {
  description = "URL del Frontend"
  value       = "http://${aws_instance.frontend.public_ip}"
}

output "ssm_connect_frontend" {
  description = "Comando para conectar al Frontend via Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.frontend.id}"
}

output "ssm_connect_backend" {
  description = "Comando para conectar al Backend via Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.backend.id}"
}

output "ssm_connect_data" {
  description = "Comando para conectar a Data via Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.data.id}"
}

# --- Pruebas de conectividad ---
output "test_connectivity" {
  description = "Comandos para verificar conectividad entre capas"
  value       = <<-EOT
    
    === PRUEBAS DE CONECTIVIDAD ===
    
    1. Desde Frontend, probar Backend (puerto 8080):
       curl http://${aws_instance.backend.private_ip}:8080/health
    
    2. Desde Backend, probar Data (MySQL puerto 3306):
       mysql -h ${aws_instance.data.private_ip} -u innovatech_user -p innovatech_db
    
    3. Verificar Docker en cualquier instancia:
       docker --version
       docker-compose --version
    
    4. Verificar Git:
       git --version
  EOT
}
