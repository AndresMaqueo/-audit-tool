@'
# MS Graph Audit Toolkit 🔍

Herramienta PowerShell para auditoría avanzada en Microsoft Entra ID usando Microsoft Graph SDK.

---

## Descripción

Este script automatiza la extracción y generación de reportes completos sobre:

- Usuarios (incluyendo invitados)
- Roles administrativos asignados
- Licencias asignadas a usuarios
- Aplicaciones registradas y sus dueños

Utiliza Microsoft Graph PowerShell SDK para obtener información crítica para auditorías y análisis de seguridad.

---

## Requisitos

- PowerShell 7.0 o superior  
- Módulo Microsoft.Graph instalado  
  ```powershell
  Install-Module Microsoft.Graph -Scope CurrentUser
