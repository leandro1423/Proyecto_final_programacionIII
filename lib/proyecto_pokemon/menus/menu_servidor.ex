defmodule ProyectoPokemon.MenuServidor do
  alias ProyectoPokemon.GestorSalas
  alias ProyectoPokemon.Servidor

  def iniciar do
    mostrar_menu()
  end

  defp mostrar_menu do
    IO.puts("""

    ============================
      SERVIDOR POKEMON ONLINE
    ============================

    Nodo actual: #{Node.self()}
    Nodos conectados: #{formatear_nodos(Node.list())}
    Gestor de salas activo: #{gestor_salas_activo?()}

    1. Ver salas de batalla activas
    2. Ver clasificación global
    3. Ver estado del servidor
    4. Ver nodos conectados
    5. Apagar menú del servidor
    ============================
    """)

    case IO.gets("> ") |> String.trim() do
      "1" ->
        mostrar_salas()
        pausar()
        mostrar_menu()

      "2" ->
        Servidor.ejecutar("clasificacion")
        |> mostrar_resultado()

        pausar()
        mostrar_menu()

      "3" ->
        mostrar_estado_servidor()
        pausar()
        mostrar_menu()

      "4" ->
        mostrar_nodos()
        pausar()
        mostrar_menu()

      "5" ->
        IO.puts("\nMenú del servidor cerrado.")
        IO.puts("El nodo sigue activo mientras no cierres IEx.\n")

      _ ->
        IO.puts("\nOpción inválida. Intenta nuevamente.\n")
        pausar()
        mostrar_menu()
    end
  end

  defp mostrar_salas do
    IO.puts("""

    ============================
      SALAS DE BATALLA ACTIVAS
    ============================
    """)

    case GestorSalas.listar_salas() do
      [] ->
        IO.puts("No hay salas activas.")

      salas ->
        Enum.each(salas, &mostrar_sala/1)
    end
  end

  defp mostrar_sala(%{
         id: id,
         jugadores: jugadores,
         estado: estado,
         tiempo_turno: tiempo_turno
       }) do
    IO.puts("""
    ----------------------------
    Sala: #{id}
    Jugadores: #{formatear_jugadores(jugadores)}
    Cantidad: #{length(jugadores)}/2
    Estado: #{estado}
    Tiempo de turno: #{tiempo_turno}s
    ----------------------------
    """)
  end

  defp mostrar_sala(sala) do
    IO.inspect(sala)
  end

  defp mostrar_estado_servidor do
    IO.puts("""

    ============================
      ESTADO DEL SERVIDOR
    ============================

    Nodo actual: #{Node.self()}
    Cookie actual: #{Node.get_cookie()}
    Nodos conectados: #{formatear_nodos(Node.list())}
    Gestor de salas activo: #{gestor_salas_activo?()}
    """)
  end

  defp mostrar_nodos do
    IO.puts("""

    ============================
      NODOS CONECTADOS
    ============================
    """)

    case Node.list() do
      [] ->
        IO.puts("No hay clientes conectados.")

      nodos ->
        Enum.each(nodos, fn nodo ->
          IO.puts("- #{nodo}")
        end)
    end
  end

  defp gestor_salas_activo? do
    case :global.whereis_name(:gestor_salas) do
      :undefined -> "No"
      _pid -> "Sí"
    end
  end

  defp formatear_nodos([]), do: "Ninguno"

  defp formatear_nodos(nodos) do
    nodos
    |> Enum.map(&Atom.to_string/1)
    |> Enum.join(", ")
  end

  defp formatear_jugadores([]), do: "Sin jugadores"

  defp formatear_jugadores(jugadores) do
    Enum.join(jugadores, ", ")
  end

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

  defp mostrar_resultado(otro) do
    IO.inspect(otro)
  end
end
