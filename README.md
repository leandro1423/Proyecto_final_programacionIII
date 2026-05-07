# ProyectoPokemon

Sistema backend desarrollado en Elixir para la gestión de entrenadores, sobres, Pokémon y batallas inspirado en Pokémon.

El proyecto utiliza:

- Persistencia en archivos JSON
- Arquitectura basada en gestores
- ETS para manejo de sesiones
- Generación aleatoria de Pokémon
- Sistema de rarezas
- Gestión de inventario y equipos
- Sistema de sobres y recompensas

---

# 1. Gestión de Entrenadores

El módulo `GestorEntrenadores` se encarga de:

- Registro de usuarios
- Inicio de sesión
- Cierre de sesión
- Gestión de inventario
- Gestión de equipos
- Persistencia automática en JSON

---

## Registro de usuario

Cuando un usuario ejecuta:

```elixir
ProyectoPokemon.Servidor.ejecutar(
  "iniciar leandro 1234"
)