defmodule ProyectoPokemon.MenuInventario do

  alias ProyectoPokemon.{
    GestorEntrenadores,
    GestorSobres
  }

  # =========================
  # INICIAR
  # =========================

  def iniciar do
    mostrar_menu()
  end

  # =========================
  # MENU INVENTARIO
  # =========================

  defp mostrar_menu do
    IO.write(IO.ANSI.clear())
    IO.write(IO.ANSI.home())

    usuario =
      GestorEntrenadores.usuario_actual()

    entrenador =
      GestorEntrenadores.buscar_entrenador(usuario)

    inventario =
      entrenador["inventario"] || []

    sobres =
      entrenador["sobres_pendientes"] || []

    IO.puts("""

    =========================
        INVENTARIO
    =========================

    Entrenador:
    #{usuario}

    =========================
    POKEMON
    =========================
    """)

    mostrar_pokemones(inventario)

    IO.puts("""

    =========================
    SOBRES PENDIENTES
    =========================
    """)

    mostrar_sobres(sobres)

    IO.puts("""

    =========================
    1. Abrir sobre
    2. Volver
    =========================
    """)

    opcion =
      IO.gets("> ")
      |> String.trim()

    manejar_opcion(opcion)
  end

  # =========================
  # MOSTRAR POKEMON
  # =========================

  defp mostrar_pokemones([]) do
    IO.puts("No tienes Pokemon aun")
  end

  defp mostrar_pokemones(pokemones) do
    Enum.each(pokemones, fn p ->

      IO.puts("""

      [##{p["id"]}] #{p["especie"]}
      Rareza: #{p["rareza"]}
      HP: #{p["hp_actual"]}/#{p["hp_max"]}
      Ataque: #{p["ataque"]}
      Defensa: #{p["defensa"]}
      Velocidad: #{p["velocidad"]}
      """)

    end)
  end

  # =========================
  # MOSTRAR SOBRES
  # =========================

  defp mostrar_sobres([]) do
    IO.puts("No tienes sobres pendientes")
  end

  defp mostrar_sobres(sobres) do
    Enum.each(sobres, fn sobre ->
      IO.puts("[##{sobre["id"]}] Sobre #{sobre["tipo"]}")
    end)
  end

  # =========================
  # OPCIONES
  # =========================

  defp manejar_opcion("1") do
    resultado =
      GestorSobres.abrir_sobre("ultimo")

    case resultado do
      {:ok, mensaje} ->
        IO.puts("\n#{mensaje}\n")

      {:error, mensaje} ->
        IO.puts("\n❌ #{mensaje}\n")
    end

    esperar()
    mostrar_menu()
  end

  defp manejar_opcion("2") do
    :ok
  end

  defp manejar_opcion(_) do
    IO.puts("\n❌ Opcion invalida")
    esperar()
    mostrar_menu()
  end

  # =========================
  # PAUSA
  # =========================

  defp esperar do
    IO.gets("\nPresiona ENTER para continuar...")
  end

end
