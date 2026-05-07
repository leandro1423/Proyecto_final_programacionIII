defmodule ProyectoPokemon.Persistencia do
  @moduledoc """
  Módulo encargado de manejar persistencia en archivos JSON.
  """

  @ruta_entrenadores "data/entrenadores.json"
  @ruta_pokemon "data/pokemon.json"
  @ruta_movimientos "data/movimientos.json"
  @ruta_batallas "data/battles.log"

  # =========================
  # ENTRENADORES
  # =========================

  def leer_trainers do
    case leer_json(@ruta_entrenadores, %{"entrenadores" => []}) do

      %{"entrenadores" => entrenadores}
      when is_list(entrenadores) ->

        Enum.map(
          entrenadores,
          &normalizar_entrenador/1
        )

      entrenadores when is_list(entrenadores) ->

        Enum.map(
          entrenadores,
          &normalizar_entrenador/1
        )

      _ ->
        []

    end
  end

  def guardar_trainers(lista)
      when is_list(lista) do

    datos = %{
      "entrenadores" => lista
    }

    guardar_json(
      @ruta_entrenadores,
      datos
    )
  end

  # =========================
  # POKEMON
  # =========================

  def leer_pokemon do
    leer_json(@ruta_pokemon, [])
  end

  # =========================
  # MOVIMIENTOS
  # =========================

  def leer_movimientos do
    leer_json(@ruta_movimientos, [])
  end

  # =========================
  # BATALLAS
  # =========================

  def registrar_batalla(texto) do
    File.write!(
      @ruta_batallas,
      texto <> "\n",
      [:append]
    )
  end

  # =========================
  # JSON
  # =========================

  defp leer_json(ruta, defecto) do

    case File.read(ruta) do

      {:ok, contenido} ->
        Jason.decode!(contenido)

      {:error, _} ->
        defecto

    end
  end

  defp guardar_json(ruta, datos) do

    json =
      Jason.encode!(
        datos,
        pretty: true
      )

    File.write!(ruta, json)
  end

  # =========================
  # NORMALIZACIÓN
  # =========================

  defp normalizar_entrenador(entrenador) do

    usuario =
      entrenador["usuario"] ||
      entrenador["nombre"] ||
      "sin_nombre"

    %{
      "usuario" => usuario,

      "clave" =>
        entrenador["clave"] || "1234",

      "monedas" =>
        entrenador["monedas"] ||
        entrenador["monedas_actuales"] ||
        0,

      "monedas_acumuladas" =>
        entrenador["monedas_acumuladas"] ||
        entrenador["monedas"] ||
        0,

      "victorias" =>
        entrenador["victorias"] || 0,

      "sobres_pendientes" =>
        normalizar_sobres(
          entrenador["sobres_pendientes"] || []
        ),

      "inventario" =>
        entrenador["inventario"] || [],

      "equipos" =>
        entrenador["equipos"] || %{},

      "equipo_actual" =>
        entrenador["equipo_actual"]
    }
  end

  defp normalizar_sobres(sobres)
       when is_integer(sobres) do

    Enum.map(
      1..sobres//1,
      fn _ ->
        %{
          "id" => :rand.uniform(900_000) + 99_999,
          "tipo" => "basico"
        }
      end
    )
  end

  defp normalizar_sobres(sobres)
       when is_list(sobres),
       do: sobres

  defp normalizar_sobres(_),
       do: []

end
