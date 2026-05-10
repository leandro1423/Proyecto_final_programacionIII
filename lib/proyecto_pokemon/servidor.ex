defmodule ProyectoPokemon.Servidor do
 alias ProyectoPokemon.{
  GestorEntrenadores,
  GestorSobres,
  GestorSalas
}

  def ejecutar(comando) when is_binary(comando) do
    comando
    |> String.trim()
    |> String.split(" ", trim: true)
    |> interpretar()
  end

  # =========================
  # ENTRENADORES
  # =========================

  defp interpretar(["iniciar", usuario, clave]),
    do: GestorEntrenadores.iniciar(usuario, clave)

  defp interpretar(["salir"]),
    do: GestorEntrenadores.salir()

  defp interpretar(["perfil"]),
    do: GestorEntrenadores.perfil()

  defp interpretar(["inventario"]),
    do: GestorEntrenadores.inventario()

  defp interpretar(["clasificacion"]),
    do: GestorEntrenadores.clasificacion()

  # =========================
  # SOBRES
  # =========================

  defp interpretar(["tienda"]),
    do: GestorSobres.tienda()

  defp interpretar(["comprar_sobre", tipo]),
    do: GestorSobres.comprar_sobre(tipo)

  defp interpretar(["abrir_sobre", id]),
    do: GestorSobres.abrir_sobre(id)

  # =========================
  # EQUIPOS
  # =========================

  defp interpretar(["crear_equipo", nombre, ids]),
    do: GestorEntrenadores.crear_equipo(nombre, ids)

  defp interpretar(["listar_equipos"]),
    do: GestorEntrenadores.listar_equipos()

  defp interpretar(["usar_equipo", nombre]),
    do: GestorEntrenadores.usar_equipo(nombre)

  # =========================
  # SALAS
  # =========================

  defp interpretar(["crear_sala"]),
    do: GestorSalas.crear_sala()

  defp interpretar(["crear_sala", "tiempo_turno=" <> segundos]),
    do: GestorSalas.crear_sala(String.to_integer(segundos))

  defp interpretar(["listar_salas"]),
    do: GestorSalas.listar_salas()

  defp interpretar(["unirse_sala", id]),
    do: GestorSalas.unirse_sala(id)

  # =========================
  # BATALLAS
  # =========================

  # TEMPORALMENTE DESACTIVADO
  # porque iniciar_batalla/3 necesita:
  # sala, pokemon1 y pokemon2

  # defp interpretar(["iniciar_batalla", sala]),
  #   do: GestorBatallas.iniciar_batalla(sala)

  # =========================
  # DEFAULT
  # =========================

  defp interpretar(_),
    do: {:error, "Comando no reconocido"}
end
