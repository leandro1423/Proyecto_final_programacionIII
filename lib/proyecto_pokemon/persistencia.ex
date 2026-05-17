defmodule ProyectoPokemon.Persistencia do
  @moduledoc "Persistencia en JSON"

  @ruta_entrenadores "data/entrenadores.json"
  @ruta_pokemon "data/pokemones.json"
  @ruta_movimientos "data/movimientos.json"
  @ruta_batallas "data/battles.log"

  # =========================
  # ENTRENADORES
  # =========================

  def leer_trainers do
    case leer_json(@ruta_entrenadores, %{"entrenadores" => []}) do
      %{"entrenadores" => list} -> normalizar_lista(list)
      list when is_list(list) -> normalizar_lista(list)
      _ -> []
    end
  end

  def guardar_trainers(lista) when is_list(lista) do
    guardar_json(@ruta_entrenadores, %{"entrenadores" => lista})
  end

  # =========================
  # POKEMON / MOVIMIENTOS
  # =========================

  def leer_pokemon, do: leer_json(@ruta_pokemon, [])
  def leer_movimientos, do: leer_json(@ruta_movimientos, [])

  # =========================
  # BATALLAS
  # =========================

  def registrar_batalla(texto) do
    File.write!(@ruta_batallas, texto <> "\n", [:append])
  end

  # =========================
  # JSON CORE
  # =========================

  defp leer_json(ruta, defecto) do
    case File.read(ruta) do
      {:ok, contenido} -> Jason.decode!(contenido)
      {:error, _} -> defecto
    end
  end

 defp guardar_json(ruta, datos) do
  json = Jason.encode!(datos, pretty: true)
  case File.write(ruta, json) do
    :ok -> :ok
    {:error, reason} -> IO.puts("ERROR guardando #{ruta}: #{reason}")
  end
end

  # =========================
  # NORMALIZACIÓN
  # =========================

  defp normalizar_lista(list), do: Enum.map(list, &normalizar_entrenador/1)

  defp normalizar_entrenador(e) do
    %{
      "usuario" => e["usuario"] || e["nombre"] || "sin_nombre",
      "clave" => e["clave"] || "1234",
      "monedas" => e["monedas"] || e["monedas_actuales"] || 0,
      "monedas_acumuladas" => e["monedas_acumuladas"] || e["monedas"] || 0,
      "victorias" => e["victorias"] || 0,
      "sobres_pendientes" => normalizar_sobres(e["sobres_pendientes"] || []),
      "inventario" => e["inventario"] || [],
      "equipos" => e["equipos"] || %{},
      "equipo_actual" => e["equipo_actual"]
    }
  end

  defp normalizar_sobres(n) when is_integer(n) do
    for _ <- 1..n do
      %{"id" => :rand.uniform(900_000) + 99_999, "tipo" => "basico"}
    end
  end

  defp normalizar_sobres(list) when is_list(list), do: list
  defp normalizar_sobres(_), do: []
end
