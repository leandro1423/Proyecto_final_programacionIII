defmodule ProyectoPokemon.MenuPrincipal do

  alias ProyectoPokemon.{
    GestorSalas,
    GestorEntrenadores,
    MenuBatalla
  }

  # =========================
  # INICIAR MENU
  # =========================

  def iniciar do
    mostrar_menu()
  end

  # =========================
  # MENU PRINCIPAL
  # =========================

  defp mostrar_menu do
    IO.write(IO.ANSI.clear())
    IO.write(IO.ANSI.home())

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

    opcion =
      IO.gets("> ")
      |> String.trim()

    case opcion do
      "1" ->
        crear_sala_batalla()

      "2" ->
        crear_sala_intercambio()
        pausar()
        mostrar_menu()

      "3" ->
        unirse_sala()

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

        IO.puts("\nSesion cerrada correctamente.\n")

      _ ->
        IO.puts("\nOpcion invalida. Intenta nuevamente.\n")
        pausar()
        mostrar_menu()
    end
  end

  # =========================
  # CREAR SALA BATALLA
  # =========================

  defp crear_sala_batalla do
    case GestorSalas.crear_sala() do

      {:ok, mensaje} ->

        IO.puts("\n✅ #{mensaje}")

        [id] =
          Regex.run(~r/S-\d+/, mensaje)

        IO.puts("""

        Recuerda:
        - Ya quedaste dentro de la sala
        - Comparte el ID con el otro jugador

        Esperando jugador...
        """)

        esperar_inicio_batalla(id)

      {:error, mensaje} ->

        IO.puts("\n❌ #{mensaje}\n")

        pausar()
        mostrar_menu()

      otro ->

        mostrar_resultado(otro)

        pausar()
        mostrar_menu()
    end
  end

  # =========================
  # ESPERAR INICIO BATALLA
  # =========================

  defp esperar_inicio_batalla(id) do

    sala =
      GestorSalas.obtener_sala(id)

    cond do

      sala == nil ->

        IO.puts("\n❌ La sala ya no existe")

        pausar()

        mostrar_menu()

      sala.estado == :en_batalla ->

        usuario =
          GestorEntrenadores.usuario_actual()

        MenuBatalla.iniciar(
          sala,
          usuario
        )

      true ->

        Process.sleep(1000)

        esperar_inicio_batalla(id)
    end
  end

  # =========================
  # CREAR SALA INTERCAMBIO
  # =========================

  defp crear_sala_intercambio do
    IO.puts("\nFuncion pendiente de implementar.\n")
  end

  # =========================
  # UNIRSE SALA
  # =========================

  defp unirse_sala do

    id =
      IO.gets("ID de sala: ")
      |> String.trim()

    case GestorSalas.unirse_sala(id) do

      {:ok, mensaje} ->

        IO.puts("\n✅ #{mensaje}")

        sala =
          GestorSalas.obtener_sala(id)

        usuario =
          GestorEntrenadores.usuario_actual()

        IO.gets("\nPresiona ENTER para iniciar batalla...")

        MenuBatalla.iniciar(
          sala,
          usuario
        )

      {:error, motivo} ->

        IO.puts("\n❌ #{motivo}")

        pausar()

        mostrar_menu()
    end
  end

  # =========================
  # MOSTRAR SALAS BATALLA
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

  # =========================
  # MOSTRAR SALAS INTERCAMBIO
  # =========================

  defp mostrar_salas_intercambio do
    IO.puts("No hay salas de intercambio disponibles")
  end

  # =========================
  # PAUSA
  # =========================

  defp pausar do
    IO.gets("\nPresiona ENTER para continuar...")
  end

  # =========================
  # MOSTRAR RESULTADOS
  # =========================

  defp mostrar_resultado({:ok, mensaje})
       when is_binary(mensaje) do

    IO.puts("\n✅ #{mensaje}\n")
  end

  defp mostrar_resultado({:ok, datos}) do

    IO.puts("\n✅ Operacion realizada correctamente:\n")

    IO.inspect(datos)
  end

  defp mostrar_resultado({:error, mensaje})
       when is_binary(mensaje) do

    IO.puts("\n❌ #{mensaje}\n")
  end

  defp mostrar_resultado(mensaje)
       when is_binary(mensaje) do

    IO.puts("\n#{mensaje}")
  end

  defp mostrar_resultado(lista)
       when is_list(lista) do

    Enum.each(lista, &IO.inspect/1)
  end

  defp mostrar_resultado(otro) do
    IO.inspect(otro)
  end

end
