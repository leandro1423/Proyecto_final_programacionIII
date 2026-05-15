defmodule ProyectoPokemon.Cluster.NodeManager do
  def conectar(nodo) do
    Node.connect(nodo)
  end

  def nodos do
    Node.list()
  end
end
