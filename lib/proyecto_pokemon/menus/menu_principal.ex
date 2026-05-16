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
    1. Crear sala de batalla
    2. Crear sala de intercambio
    3. Unirse a sala existente
    4. Ver perfil
    5. Ver inventario
    6. Cerrar sesión
    ==========================
    """)

    case IO.gets("> ") |> String.trim() do
      "1" ->
        crear_sala_batalla()
        pausar()
        mostrar_menu()

      "2" ->
        crear_sala_intercambio()
        pausar()
        mostrar_menu()

      "3" ->
        unirse_sala()
        pausar()
        mostrar_menu()

      "4" ->
        ProyectoPokemon.Servidor.ejecutar("perfil")
        |> mostrar_resultado()

        pausar()
        mostrar_menu()

      "5" ->
        ProyectoPokemon.Servidor.ejecutar("inventario")
        |> mostrar_resultado()

        pausar()
        mostrar_menu()

      "6" ->
        ProyectoPokemon.Servidor.ejecutar("salir")
        |> mostrar_resultado()

        IO.puts("\nSesión cerrada correctamente.\n")

      _ ->
        IO.puts("\nOpción inválida. Intenta nuevamente.\n")
        pausar()
        mostrar_menu()
    end
  end

  # =========================
  # OPCIONES DEL MENÚ
  # =========================

  defp crear_sala_batalla do
    case GestorSalas.crear_sala() do
      {:ok, mensaje} ->
        IO.puts("\n✅ #{mensaje}")
        IO.puts("Recuerda: al crear una sala ya quedas dentro de ella.")
        IO.puts("Comparte el ID de la sala con el otro jugador.\n")

      {:error, mensaje} ->
        IO.puts("\n❌ #{mensaje}\n")

      otro ->
        mostrar_resultado(otro)
    end
  end

  defp crear_sala_intercambio do
    IO.puts("\nFunción de sala de intercambio pendiente de implementar.\n")
  end

  defp unirse_sala do
    id =
      IO.gets("ID de sala: ")
      |> String.trim()

    ProyectoPokemon.Servidor.ejecutar("unirse_sala " <> id)
    |> mostrar_resultado()
  end

  # =========================
  # MOSTRAR SALAS
  # =========================

  defp mostrar_salas_batalla do
    case GestorSalas.listar_salas() do
      [] ->
        IO.puts("No hay salas disponibles")

      salas ->
        Enum.each(salas, &mostrar_sala_batalla/1)
    end
  end

  defp mostrar_sala_batalla(%{
         id: id,
         jugadores: jugadores,
         estado: estado,
         tiempo_turno: tiempo_turno
       }) do
    IO.puts(
      "- Sala #{id} | Jugadores: #{length(jugadores)}/2 | Estado: #{estado} | Turno: #{tiempo_turno}s"
    )
  end

  defp mostrar_sala_batalla(sala) do
    IO.inspect(sala)
  end

  defp mostrar_salas_intercambio do
    IO.puts("No hay salas de intercambio disponibles")
  end

  # =========================
  # AUXILIARES
  # =========================

  defp pausar do
    IO.gets("\nPresiona ENTER para continuar...")
  end

  defp mostrar_resultado({:ok, mensaje}) when is_binary(mensaje) do
    IO.puts("\n✅ #{mensaje}\n")
  end

  defp mostrar_resultado({:ok, datos}) do
    IO.puts("\n✅ Operación realizada correctamente:\n")
    IO.inspect(datos)
  end

  defp mostrar_resultado({:error, mensaje}) when is_binary(mensaje) do
    IO.puts("\n❌ #{mensaje}\n")
  end

  defp mostrar_resultado(mensaje) when is_binary(mensaje) do
    IO.puts("\n" <> mensaje)
  end

  defp mostrar_resultado(lista) when is_list(lista) do
    Enum.each(lista, &IO.inspect/1)
  end

  defp mostrar_resultado(otro) do
    IO.inspect(otro)
  end
end
