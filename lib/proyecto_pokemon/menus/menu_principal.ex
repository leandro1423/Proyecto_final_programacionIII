defmodule ProyectoPokemon.MenuPrincipal do

  alias ProyectoPokemon.GestorSalas

  def iniciar do
    mostrar_menu()
  end

  defp mostrar_menu do

    IO.puts("""
    ==========================
        POKEMON ONLINE
    ==========================

    SALAS DE BATALLA DISPONIBLES
    """)

    mostrar_salas_batalla()

    IO.puts("""

    SALAS DE INTERCAMBIO DISPONIBLES
    """)

    mostrar_salas_intercambio()

    IO.puts("""

    ==========================
    1. Crear sala batalla
    2. Crear sala intercambio
    3. Unirse a sala
    4. Perfil
    5. Inventario
    6. Cerrar sesión
    ==========================
    """)

    case IO.gets("> ") |> String.trim() do

      "1" ->
        GestorSalas.crear_sala()
        mostrar_menu()

      "2" ->
        IO.puts("Creando sala de intercambio...")
        mostrar_menu()

      "3" ->
        unirse_sala()

      "4" ->
        IO.inspect(ProyectoPokemon.Servidor.ejecutar("perfil"))
        mostrar_menu()

      "5" ->
        IO.inspect(ProyectoPokemon.Servidor.ejecutar("inventario"))
        mostrar_menu()

      "6" ->
        ProyectoPokemon.Servidor.ejecutar("salir")
        IO.puts("Sesión cerrada")

      _ ->
        mostrar_menu()
    end
  end

  defp mostrar_salas_batalla do

    salas = GestorSalas.listar_salas()

    case salas do
      [] ->
        IO.puts("No hay salas disponibles")

      _ ->
        Enum.each(salas, fn sala ->
          IO.puts("- Sala #{sala.id}")
        end)
    end
  end

  defp mostrar_salas_intercambio do
    IO.puts("No hay salas de intercambio disponibles")
  end

  defp unirse_sala do

    id =
      IO.gets("ID de sala: ")
      |> String.trim()

    IO.inspect(
      ProyectoPokemon.Servidor.ejecutar("unirse_sala " <> id)
    )

    mostrar_menu()
  end

end
