defmodule ProyectoPokemon.Application do
  use Application

  def start(_type, _args) do
    children =
      Node.self()
      |> Atom.to_string()
      |> procesos_segun_nodo()

    opts = [
      strategy: :one_for_one,
      name: ProyectoPokemon.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end

  # =========================
  # PROCESOS SEGÚN EL NODO
  # =========================

  defp procesos_segun_nodo("servidor@" <> _host) do
    [
      ProyectoPokemon.GestorSalas
    ]
  end

  defp procesos_segun_nodo(_otro_nodo) do
    []
  end
end
