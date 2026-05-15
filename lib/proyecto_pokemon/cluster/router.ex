defmodule ProyectoPokemon.Cluster.Router do

  def nodo_batallas do
    Enum.random([
      :"batallas@127.0.0.1",
      :"batallas2@127.0.0.1"
    ])
  end

  def nodo_intercambios do
    Enum.random([
      :"intercambios@127.0.0.1",
      :"intercambios2@127.0.0.1"
    ])
  end

end
