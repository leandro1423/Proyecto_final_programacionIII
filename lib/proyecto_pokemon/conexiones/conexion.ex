defmodule ProyectoPokemon.Conexion do
  alias ProyectoPokemon.Adapters.{
    LocalAdapter,
    RemoteAdapter
  }

  def adapter do
    if Node.list() == [] do
      LocalAdapter
    else
      RemoteAdapter
    end
  end

  def crear_sala do
    adapter().crear_sala()
  end

  def listar_salas do
    adapter().listar_salas()
  end

  def unirse_sala(id) do
    adapter().unirse_sala(id)
  end

  def salir_sala(id) do
    adapter().salir_sala(id)
  end
end
