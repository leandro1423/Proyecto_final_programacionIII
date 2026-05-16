defmodule ProyectoPokemon.Application do
  use Application

  def start(_type, _args) do
    es_servidor =
      String.starts_with?(
        Atom.to_string(Node.self()),
        "servidor@"
      )

    children =
      if es_servidor do
        [
          ProyectoPokemon.GestorSalas
        ]
      else
        []
      end

    opts = [
      strategy: :one_for_one,
      name: ProyectoPokemon.Supervisor
    ]

    Supervisor.start_link(children, opts)
  end
end
