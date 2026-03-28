defmodule ProyectoPokemon.Persistencia do
  @ruta_trainers "data/trainers.json"

  # Leer entrenadores
  def leer_trainers do
    case File.read(@ruta_trainers) do
      {:ok, contenido} ->
        Jason.decode!(contenido)

      {:error, _} ->
        []
    end
  end

  # Guardar entrenadores
  def guardar_trainers(lista) do
    json = Jason.encode!(lista, pretty: true)
    File.write!(@ruta_trainers, json)
  end
end
