defmodule ProyectoPokemon.ConexionBehaviour do
  @callback crear_sala() :: any()
  @callback listar_salas() :: any()
  @callback unirse_sala(String.t()) :: any()
  @callback salir_sala(String.t()) :: any()
end
