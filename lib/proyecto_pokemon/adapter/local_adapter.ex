defmodule ProyectoPokemon.Adapters.LocalAdapter do
  @behaviour ProyectoPokemon.ConexionBehaviour

  alias ProyectoPokemon.GestorSalas

  def crear_sala do
    GestorSalas.crear_sala()
  end

  def listar_salas do
    GestorSalas.listar_salas()
  end

  def unirse_sala(id) do
    GestorSalas.unirse_sala(id)
  end

  def salir_sala(id) do
    GestorSalas.salir_sala(id)
  end
end
