defmodule ProyectoPokemon.Adapters.RemoteAdapter do
  @behaviour ProyectoPokemon.ConexionBehaviour

  defp server do
    List.first(Node.list())
  end

  def crear_sala do
    :rpc.call(
      server(),
      ProyectoPokemon.GestorSalas,
      :crear_sala,
      []
    )
  end

  def listar_salas do
    :rpc.call(
      server(),
      ProyectoPokemon.GestorSalas,
      :listar_salas,
      []
    )
  end

  def unirse_sala(id) do
    :rpc.call(
      server(),
      ProyectoPokemon.GestorSalas,
      :unirse_sala,
      [id]
    )
  end

  def salir_sala(id) do
    :rpc.call(
      server(),
      ProyectoPokemon.GestorSalas,
      :salir_sala,
      [id]
    )
  end
end
