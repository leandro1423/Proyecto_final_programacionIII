defmodule ProyectoPokemon.MenuBatalla do

  # =========================
  # MENU PRINCIPAL BATALLA
  # =========================

  def iniciar(sala, usuario) do
    mostrar_batalla(sala, usuario)
  end

  # =========================
  # MOSTRAR BATALLA
  # =========================

  defp mostrar_batalla(sala, usuario) do
    IO.write(IO.ANSI.clear())
    IO.write(IO.ANSI.home())

    enemigo =
      obtener_enemigo(sala, usuario)

    IO.puts("""
    ==========================================
              BATALLA POKEMON
    ==========================================

    Sala: #{sala.id}

    Jugador actual:
    #{usuario}

    ==========================================
    ENEMIGO
    ==========================================

    #{enemigo}

    ==========================================
    TU EQUIPO
    ==========================================

    1. Pokemon 1
    HP: 100/100
    Ataque: 50
    Rareza: Comun

    ----------------------------

    2. Pokemon 2
    HP: 100/100
    Ataque: 60
    Rareza: Raro

    ----------------------------

    3. Pokemon 3
    HP: 100/100
    Ataque: 70
    Rareza: Epico

    ==========================================
    ACCIONES
    ==========================================

    1. Atacar
    2. Cambiar Pokemon
    3. Abandonar batalla

    ==========================================
    """)

    opcion =
      case IO.gets("Seleccione una opcion: ") do
        :eof ->
          ""

        {:error, _} ->
          ""

        entrada ->
          String.trim(entrada)
      end

    manejar_opcion(opcion, sala, usuario)
  end

  # =========================
  # OPCIONES MENU
  # =========================

  defp manejar_opcion("1", sala, usuario) do
    IO.puts("\nSeleccionaste atacar")
    esperar()
    mostrar_batalla(sala, usuario)
  end

  defp manejar_opcion("2", sala, usuario) do
    IO.puts("\nSeleccionaste cambiar Pokemon")
    esperar()
    mostrar_batalla(sala, usuario)
  end

  defp manejar_opcion("3", sala, _usuario) do

  case ProyectoPokemon.GestorSalas.salir_sala(sala.id) do

    {:ok, mensaje} ->

      IO.puts("\n#{mensaje}")

    {:error, motivo} ->

      IO.puts("\n#{motivo}")
  end

  esperar()
end

  defp manejar_opcion(_, sala, usuario) do
    IO.puts("\nOpcion invalida")
    esperar()
    mostrar_batalla(sala, usuario)
  end

  # =========================
  # OBTENER ENEMIGO
  # =========================

  defp obtener_enemigo(sala, usuario) do
    Enum.find(
      sala.jugadores,
      fn jugador ->
        jugador != usuario
      end
    ) || "Esperando rival..."
  end

  # =========================
  # PAUSA
  # =========================

  defp esperar do
    IO.gets("\nPresione ENTER para continuar...")
  end

end
