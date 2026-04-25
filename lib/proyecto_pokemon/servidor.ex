defmodule ProyectoPokemon.Servidor do
  alias ProyectoPokemon.{GestorEntrenadores, GestorSobres, GestorBatallas}

  def ejecutar(comando) when is_binary(comando) do
    comando
    |> String.trim()
    |> String.split(" ", trim: true)
    |> interpretar()
  end

  defp interpretar(["iniciar", usuario, clave]), do: GestorEntrenadores.iniciar(usuario, clave)
  defp interpretar(["salir"]), do: GestorEntrenadores.salir()
  defp interpretar(["perfil"]), do: GestorEntrenadores.perfil()
  defp interpretar(["inventario"]), do: GestorEntrenadores.inventario()
  defp interpretar(["clasificacion"]), do: GestorEntrenadores.clasificacion()
  defp interpretar(["tienda"]), do: GestorSobres.tienda()
  defp interpretar(["comprar_sobre", tipo]), do: GestorSobres.comprar_sobre(tipo)
  defp interpretar(["abrir_sobre", id]), do: GestorSobres.abrir_sobre(id)
  defp interpretar(["crear_equipo", nombre, ids]), do: GestorEntrenadores.crear_equipo(nombre, ids)
  defp interpretar(["listar_equipos"]), do: GestorEntrenadores.listar_equipos()
  defp interpretar(["usar_equipo", nombre]), do: GestorEntrenadores.usar_equipo(nombre)
  defp interpretar(["listar_salas"]), do: GestorBatallas.listar_salas()
  defp interpretar(["crear_sala"]), do: GestorBatallas.crear_sala()
  defp interpretar(["crear_sala", "tiempo_turno=" <> segundos]), do: GestorBatallas.crear_sala(String.to_integer(segundos))
  defp interpretar(["unirse_sala", id]), do: GestorBatallas.unirse_sala(id)

  defp interpretar(_), do: {:error, "Comando no reconocido"}
end
