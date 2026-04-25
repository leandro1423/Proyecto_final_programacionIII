defmodule ProyectoPokemon.GestorSobres do
  alias ProyectoPokemon.{Persistencia, GestorEntrenadores}

  @tienda %{
    "basico" => %{"precio" => 100, "probabilidades" => %{"comun" => 70, "raro" => 25, "epico" => 5}},
    "avanzado" => %{"precio" => 250, "probabilidades" => %{"comun" => 40, "raro" => 45, "epico" => 15}}
  }

  def tienda do
    """
    === Tienda ===
    básico: 100 monedas | común 70% | raro 25% | épico 5%
    avanzado: 250 monedas | común 40% | raro 45% | épico 15%
    """
  end

  def comprar_sobre(tipo, usuario \\ nil) do
    tipo = normalizar_tipo(tipo)
    sobre = @tienda[tipo]

    if sobre == nil do
      {:error, "Tipo de sobre no válido"}
    else
      GestorEntrenadores.actualizar_entrenador_en_sesion(usuario, fn entrenador ->
        precio = sobre["precio"]

        if entrenador["monedas"] < precio do
          {:error, "Monedas insuficientes"}
        else
          nuevo_sobre = %{"id" => generar_id(), "tipo" => tipo}

          nuevo =
            entrenador
            |> Map.put("monedas", entrenador["monedas"] - precio)
            |> Map.put("sobres_pendientes", (entrenador["sobres_pendientes"] || []) ++ [nuevo_sobre])

          {:ok, nuevo, "Compraste un sobre #{tipo}. ID: #{nuevo_sobre["id"]}"}
        end
      end)
    end
  end

  def abrir_sobre(id_o_ultimo, usuario \\ nil) do
    GestorEntrenadores.actualizar_entrenador_en_sesion(usuario, fn entrenador ->
      sobres = entrenador["sobres_pendientes"] || []
      sobre = buscar_sobre(sobres, id_o_ultimo)

      if sobre == nil do
        {:error, "No se encontró el sobre"}
      else
        pokemones = Enum.map(1..3, fn _ -> crear_pokemon(entrenador["usuario"], sobre["tipo"]) end)
        nuevos_sobres = Enum.reject(sobres, fn s -> s["id"] == sobre["id"] end)
        inventario = entrenador["inventario"] || []

        nuevo =
          entrenador
          |> Map.put("sobres_pendientes", nuevos_sobres)
          |> Map.put("inventario", pokemones ++ inventario)

        {:ok, nuevo, formato_sobre_abierto(pokemones)}
      end
    end)
  end

  def crear_pokemon(dueno, tipo_sobre) do
    especie = Enum.random(Persistencia.leer_pokemon())
    rareza = sortear_rareza(tipo_sobre)
    factor = sortear_factor(rareza)

    %{
      "id" => generar_id(),
      "especie" => especie["nombre"],
      "tipos" => especie["tipos"],
      "dueno_original" => dueno,
      "rareza" => rareza,
      "ataque" => calcular_stat(especie["ataque_base"], factor),
      "defensa" => calcular_stat(especie["defensa_base"], factor),
      "velocidad" => calcular_stat(especie["velocidad_base"], factor),
      "movimientos" => asignar_movimientos(especie["tipos"])
    }
  end

  def asignar_movimientos(tipos) do
    movimientos = movimientos_planos()

    obligatorios =
      case tipos do
        [tipo] -> movimientos_por_tipo(tipo) |> Enum.take_random(2)
        [tipo1, tipo2 | _] -> Enum.take_random(movimientos_por_tipo(tipo1), 1) ++ Enum.take_random(movimientos_por_tipo(tipo2), 1)
        _ -> []
      end

    faltantes = 4 - length(obligatorios)
    nombres_obligatorios = Enum.map(obligatorios, & &1["nombre"])

    complementarios =
      movimientos
      |> Enum.reject(fn m -> m["nombre"] in nombres_obligatorios end)
      |> Enum.take_random(faltantes)

    obligatorios ++ complementarios
  end

  defp movimientos_planos do
    Persistencia.leer_movimientos()
    |> Enum.flat_map(fn grupo ->
      Enum.map(grupo["movimientos"], fn mov ->
        %{"nombre" => mov["nombre"], "tipo" => grupo["tipo"], "potencia" => mov["potencia"] || mov["poder_base"]}
      end)
    end)
  end

  defp movimientos_por_tipo(tipo), do: Enum.filter(movimientos_planos(), fn m -> m["tipo"] == tipo end)

  defp sortear_rareza(tipo_sobre) do
    probabilidades = @tienda[tipo_sobre]["probabilidades"]
    n = :rand.uniform(100)

    cond do
      n <= probabilidades["comun"] -> "comun"
      n <= probabilidades["comun"] + probabilidades["raro"] -> "raro"
      true -> "epico"
    end
  end

  defp sortear_factor("comun"), do: :rand.uniform(7) + 1
  defp sortear_factor("raro"), do: :rand.uniform(11) + 9
  defp sortear_factor("epico"), do: :rand.uniform(16) + 24

  defp calcular_stat(base, factor), do: round(base * (1 + factor / 100))

  defp buscar_sobre([], _), do: nil
  defp buscar_sobre(sobres, "ultimo"), do: List.last(sobres)
  defp buscar_sobre(sobres, :ultimo), do: List.last(sobres)

  defp buscar_sobre(sobres, id) when is_binary(id) do
    case Integer.parse(id) do
      {numero, ""} -> buscar_sobre(sobres, numero)
      _ -> nil
    end
  end

  defp buscar_sobre(sobres, id), do: Enum.find(sobres, fn s -> s["id"] == id end)

  defp formato_sobre_abierto(pokemones) do
    cuerpo =
      pokemones
      |> Enum.with_index(1)
      |> Enum.map(fn {p, i} ->
        movimientos =
          p["movimientos"]
          |> Enum.map(fn m -> "#{m["nombre"]} (#{m["potencia"]})" end)
          |> Enum.join(", ")

        "#{i}. [##{p["id"]}] #{p["especie"]} (#{Enum.join(p["tipos"], "/")}) [#{p["rareza"]}] - Dueño original: #{p["dueno_original"]}\n   Movimientos: #{movimientos}"
      end)
      |> Enum.join("\n")

    "¡Sobre abierto! Obtuviste:\n" <> cuerpo
  end

  defp normalizar_tipo("básico"), do: "basico"
  defp normalizar_tipo(tipo), do: String.downcase(tipo)
  defp generar_id, do: :rand.uniform(900_000) + 99_999
end
