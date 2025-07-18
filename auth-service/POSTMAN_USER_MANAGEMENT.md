# 📋 Gestión Completa de Usuarios - Endpoints para Postman

## 🔧 Configuración Base
- **URL Base**: `http://localhost:4001`
- **Autenticación**: Bearer Token (obtenido del login)
- **Permisos**: Administrador o Director

## 👥 Endpoints de Gestión de Usuarios

### 1. Obtener Todos los Usuarios (Completo)
- **URL**: `GET http://localhost:4001/api/users/`
- **Headers**: 
  ```
  Authorization: Bearer {token}
  Content-Type: application/json
  ```
- **Permisos**: Administrador o Director
- **Respuesta**: Lista completa de usuarios con todos los campos

### 2. Obtener Usuario por ID
- **URL**: `GET http://localhost:4001/api/users/{id}`
- **Headers**: 
  ```
  Authorization: Bearer {token}
  Content-Type: application/json
  ```
- **Permisos**: Administrador, Director o el propio usuario

### 3. Actualizar Usuario Completo
- **URL**: `PUT http://localhost:4001/api/users/{id}`
- **Headers**: 
  ```
  Authorization: Bearer {token}
  Content-Type: application/json
  ```
- **Body (JSON)** - Todos los campos son opcionales:
```json
{
  "username": "nuevo_usuario",
  "firstName": "Nombre",
  "lastName": "Apellido",
  "email": "nuevo@email.com",
  "department": "informatica",
  "role": "empleado",
  "jobTitle": "Desarrollador Senior",
  "isActive": true
}
```

**Departamentos válidos:**
- `informatica`
- `administracion`
- `internacional`
- `compras`
- `gerencia`
- `oficina_tecnica`
- `calidad`
- `laboratorio`
- `rrhh`
- `logistica`
- `mantenimiento`
- `softgel`
- `produccion`
- `sin_departamento`

**Roles válidos:**
- `director` (solo puede ser asignado por directores)
- `administrador`
- `empleado`

### 4. Cambiar Contraseña de Usuario
- **URL**: `PATCH http://localhost:4001/api/users/{id}/change-password`
- **Headers**: 
  ```
  Authorization: Bearer {token}
  Content-Type: application/json
  ```
- **Permisos**: Solo Administrador o Director
- **Body (JSON)**:
```json
{
  "newPassword": "nueva_contraseña_123"
}
```
- **Validaciones**: 
  - Contraseña mínimo 6 caracteres
  - No requiere contraseña actual (es para administradores)

### 5. Eliminar Usuario
- **URL**: `DELETE http://localhost:4001/api/users/{id}`
- **Headers**: 
  ```
  Authorization: Bearer {token}
  Content-Type: application/json
  ```
- **Permisos**: Solo Administrador

### 6. Actualizar Solo el Rol
- **URL**: `PATCH http://localhost:4001/api/users/{id}/role`
- **Headers**: 
  ```
  Authorization: Bearer {token}
  Content-Type: application/json
  ```
- **Permisos**: Solo Administrador
- **Body (JSON)**:
```json
{
  "role": "user"
}
```

## 🔐 Niveles de Permisos

### Director
- ✅ Ver todos los usuarios
- ✅ Editar todos los campos de cualquier usuario
- ✅ Cambiar roles (incluyendo asignar director)
- ✅ Cambiar contraseñas
- ✅ Activar/desactivar usuarios

### Administrador
- ✅ Ver todos los usuarios
- ✅ Editar campos básicos de cualquier usuario
- ❌ No puede cambiar roles a director
- ✅ Cambiar contraseñas
- ✅ Activar/desactivar usuarios
- ✅ Eliminar usuarios

### Empleado
- ✅ Ver su propio perfil
- ✅ Editar solo sus datos básicos (nombre, apellido, email)
- ❌ No puede cambiar departamento, rol o estado

## 📝 Ejemplos de Uso en Postman

### Ejemplo 1: Obtener todos los usuarios
```
GET http://localhost:4001/api/users/
Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Ejemplo 2: Actualizar usuario completo
```
PUT http://localhost:4001/api/users/5
Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  Content-Type: application/json

Body:
{
  "firstName": "Juan Carlos",
  "lastName": "Pérez García",
  "email": "juan.perez@naturepharma.com",
  "department": "laboratorio",
  "jobTitle": "Técnico de Laboratorio Senior",
  "isActive": true
}
```

### Ejemplo 3: Cambiar contraseña
```
PATCH http://localhost:4001/api/users/5/change-password
Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
  Content-Type: application/json

Body:
{
  "newPassword": "nuevaPassword123!"
}
```

## 🚨 Códigos de Error Comunes

- **401**: Token inválido o expirado
- **403**: Sin permisos suficientes
- **404**: Usuario no encontrado
- **400**: Datos de entrada inválidos
- **409**: Conflicto (ej: email ya existe)

## 📊 Respuesta de Éxito

Todas las respuestas exitosas siguen este formato:
```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "usuario",
    "email": "email@example.com",
    "firstName": "Nombre",
    "lastName": "Apellido",
    "role": "empleado",
    "department": "informatica",
    "jobTitle": "Desarrollador",
    "isActive": true,
    "createdAt": "2024-01-01T00:00:00.000Z",
    "updatedAt": "2024-01-01T00:00:00.000Z",
    "lastLogin": "2024-01-01T00:00:00.000Z"
  },
  "message": "Operation completed successfully"
}
```

---

**Nota**: Estos endpoints proporcionan gestión completa de usuarios para administradores y directores del sistema NaturePharma.