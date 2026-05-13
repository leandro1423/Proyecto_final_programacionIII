defmodule ProyectoPokemon.GestorBatallas do
  alias ProyectoPokemon.{
    Persistencia,
    GestorEntrenadores
  }

  def iniciar_batalla(id_sala, pokemon1, pokemon2) do
    batalla = %{
      sala: id_sala,
      pokemon1: pokemon1,
      pokemon2: pokemon2,
      estado: :activa
    }

    {:ok, batalla}
  end

  def registrar_resultado(
        ganador,
        perdedor,
        resumen \\ "Batalla finalizada"
      ) do

    GestorEntrenadores.recompensar(
      ganador,
      perdedor
    )

    fecha =
      DateTime.utc_now()
      |> DateTime.to_iso8601()

    nodo =
      Node.self()
      |> Atom.to_string()

    Persistencia.registrar_batalla(
      "#{fecha} | ganador=#{ganador} | perdedor=#{perdedor} | nodo=#{nodo} | #{resumen}"
    )

    {:ok,
     "Resultado registrado. #{ganador} +100 monedas, #{perdedor} +30 monedas"}
  end
end
