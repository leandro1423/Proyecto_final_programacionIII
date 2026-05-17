defmodule ProyectoPokemon.GestorSobres do
  alias ProyectoPokemon.{GestorEntrenadores, Persistencia}

  @tienda %{
    "basico" => %{
      "precio" => 100,
      "probabilidades" => %{
        "comun" => 70,
        "raro" => 25,
        "epico" => 5
      }
    },
    "avanzado" => %{
      "precio" => 250,
      "probabilidades" => %{
        "comun" => 40,
        "raro" => 45,
        "epico" => 15
      }
    }
  }

  # =========================
  # TIENDA
  # =========================

  def tienda do
    """
    === Tienda ===

    básico:
    Precio: 100 monedas
    común 70%
    raro 25%
    épico 5%

    avanzado:
    Precio: 250 monedas
    común 40%
    raro 45%
    épico 15%
    """
  end

  # =========================
  # COMPRAR SOBRE
  # =========================

  def comprar_sobre(tipo, usuario \\ nil) do
    tipo = normalizar_tipo(tipo)
    sobre = @tienda[tipo]

    if sobre == nil do
      {:error, "Tipo de sobre no válido"}
    else
      GestorEntrenadores.actualizar_entrenador_en_sesion(usuario, fn entrenador ->
        precio = sobre["precio"]

        cond do
          entrenador["monedas"] < precio ->
            {:error, "Monedas insuficientes"}

          true ->
            nuevo_sobre = %{
              "id" => generar_id(),
              "tipo" => tipo
            }

            nuevo_entrenador =
              entrenador
              |> Map.put("monedas", entrenador["monedas"] - precio)
              |> Map.update("sobres_pendientes", [nuevo_sobre], fn sobres ->
                sobres ++ [nuevo_sobre]
              end)

            {:ok, nuevo_entrenador, "Compraste un sobre #{tipo}. ID: #{nuevo_sobre["id"]}"}
        end
      end)
    end
  end

  # =========================
  # ABRIR SOBRE
  # =========================

  def abrir_sobre(id_o_ultimo, usuario \\ nil) do
    GestorEntrenadores.actualizar_entrenador_en_sesion(usuario, fn entrenador ->
      sobres = entrenador["sobres_pendientes"] || []
      sobre = buscar_sobre(sobres, id_o_ultimo)

      if sobre == nil do
        {:error, "No se encontró el sobre"}
      else
        pokemones_disponibles = pokemones_para_sobre(sobre["tipo"])

        pokemones =
          pokemones_disponibles
          |> Enum.shuffle()
          |> Enum.take(3)
          |> Enum.map(fn especie ->
            crear_pokemon_desde_especie(entrenador["usuario"], sobre["tipo"], especie)
          end)

        nuevos_sobres = Enum.reject(sobres, fn s -> s["id"] == sobre["id"] end)
        inventario_actual = Map.get(entrenador, "inventario", [])

        nuevo_entrenador =
          Map.merge(entrenador, %{
            "sobres_pendientes" => nuevos_sobres,
            "inventario" => pokemones ++ inventario_actual
          })

        # Debug en consola
        IO.inspect(length(nuevo_entrenador["inventario"]), label: "INVENTARIO NUEVO SIZE")
        IO.inspect(nuevo_entrenador["usuario"], label: "GUARDANDO PARA")

        # Retorno exitoso con el estado modificado y el string formateado
        {:ok, nuevo_entrenador, formato_sobre_abierto(pokemones)}
      end
    end)
  end

  # =========================
  # CREAR POKEMON
  # =========================

  def crear_pokemon_desde_especie(dueno, tipo_sobre, especie) do
    rareza = sortear_rareza(tipo_sobre)
    factor = sortear_factor(rareza)
    hp = calcular_stat(especie["hp_base"], factor)

    %{
      "id" => generar_id(),
      "especie" => especie["nombre"],
      "tipos" => especie["tipos"],
      "dueno_original" => dueno,
      "rareza" => rareza,
      "factor_rareza" => factor,
      "hp_max" => hp,
      "hp_actual" => hp,
      "ataque" => calcular_stat(especie["ataque_base"], factor),
      "defensa" => calcular_stat(especie["defensa_base"], factor),
      "velocidad" => calcular_stat(especie["velocidad_base"], factor),
      "movimientos" => asignar_movimientos(especie["tipos"])
    }
  end

  # =========================
  # POKEMON DISPONIBLES
  # =========================

  defp pokemones_para_sobre("basico") do
    Persistencia.leer_pokemon()
    |> Enum.filter(fn pokemon ->
      pokemon["rareza"] in ["comun", "raro"]
    end)
  end

  defp pokemones_para_sobre("avanzado") do
    Persistencia.leer_pokemon()
  end

  # =========================
  # MOVIMIENTOS
  # =========================

  def asignar_movimientos(tipos) do
    movimientos = movimientos_planos()

    movimientos_tipo =
      tipos
      |> Enum.flat_map(fn tipo -> movimientos_por_tipo(tipo) end)
      |> Enum.uniq_by(fn m -> m["nombre"] end)

    obligatorios =
      movimientos_tipo
      |> Enum.take_random(min(2, length(movimientos_tipo)))

    nombres_usados = Enum.map(obligatorios, fn m -> m["nombre"] end)

    restantes = Enum.reject(movimientos, fn m -> m["nombre"] in nombres_usados end)
    complementarios = Enum.take_random(restantes, 4 - length(obligatorios))

    obligatorios ++ complementarios
  end

  defp movimientos_planos do
    Persistencia.leer_movimientos()
    |> Enum.flat_map(fn grupo ->
      Enum.map(grupo["movimientos"], fn mov ->
        %{
          "nombre" => mov["nombre"],
          "tipo" => grupo["tipo"],
          "potencia" => mov["potencia"] || mov["poder_base"]
        }
      end)
    end)
  end

  defp movimientos_por_tipo(tipo) do
    Enum.filter(movimientos_planos(), fn movimiento ->
      movimiento["tipo"] == tipo
    end)
  end

  # =========================
  # RAREZA
  # =========================

  defp sortear_rareza(tipo_sobre) do
    probabilidades = @tienda[tipo_sobre]["probabilidades"]
    n = :rand.uniform(100)

    cond do
      n <= probabilidades["comun"] ->
        "comun"

      n <= probabilidades["comun"] + probabilidades["raro"] ->
        "raro"

      true ->
        "epico"
    end
  end

  # =========================
  # FACTORES DE RAREZA
  # =========================

  defp sortear_factor("comun"), do: Enum.random(2..8)
  defp sortear_factor("raro"), do: Enum.random(10..20)
  defp sortear_factor("epico"), do: Enum.random(25..40)

  # =========================
  # CALCULO STATS
  # =========================

  defp calcular_stat(base, factor) do
    round(base * (1 + factor / 100))
  end

  # =========================
  # SOBRES
  # =========================

  defp buscar_sobre([], _), do: nil
  defp buscar_sobre(sobres, "ultimo"), do: List.last(sobres)
  defp buscar_sobre(sobres, :ultimo), do: List.last(sobres)

  defp buscar_sobre(sobres, id) when is_binary(id) do
    case Integer.parse(id) do
      {numero, ""} -> buscar_sobre(sobres, numero)
      _ -> nil
    end
  end

  defp buscar_sobre(sobres, id) do
    Enum.find(sobres, fn sobre -> sobre["id"] == id end)
  end

  # =========================
  # FORMATO
  # =========================

  defp formato_sobre_abierto(pokemones) do
    cuerpo =
      pokemones
      |> Enum.with_index(1)
      |> Enum.map(fn {pokemon, i} ->
        movimientos =
          pokemon["movimientos"]
          |> Enum.map(fn mov -> "#{mov["nombre"]} (#{mov["potencia"]})" end)
          |> Enum.join(", ")

        """
        #{i}. [##{pokemon["id"]}] #{pokemon["especie"]}
        Tipos: #{Enum.join(pokemon["tipos"], "/")}
        Rareza: #{pokemon["rareza"]}
        Factor rareza: #{pokemon["factor_rareza"]}%
        HP: #{pokemon["hp_actual"]}/#{pokemon["hp_max"]}
        Ataque: #{pokemon["ataque"]}
        Defensa: #{pokemon["defensa"]}
        Velocidad: #{pokemon["velocidad"]}
        Movimientos: #{movimientos}
        """
      end)
      |> Enum.join("\n")

    "¡Sobre abierto!\n\n" <> cuerpo
  end

  # =========================
  # UTILS
  # =========================

  defp normalizar_tipo("básico"), do: "basico"
  defp normalizar_tipo(tipo), do: String.downcase(tipo)

  defp generar_id do
    :rand.uniform(900_000) + 99_999
  end
end
