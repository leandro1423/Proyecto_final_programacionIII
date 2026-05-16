defmodule ProyectoPokemon.GestorSobres do
  alias ProyectoPokemon.{Persistencia, GestorEntrenadores}

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
      GestorEntrenadores.actualizar_entrenador_en_sesion(
        usuario,
        fn entrenador ->
          precio = sobre["precio"]

          if entrenador["monedas"] < precio do
            {:error, "Monedas insuficientes"}
          else
            nuevo_sobre = %{
              "id" => generar_id(),
              "tipo" => tipo
            }

            nuevo =
              entrenador
              |> Map.put(
                "monedas",
                entrenador["monedas"] - precio
              )
              |> Map.put(
                "sobres_pendientes",
                (entrenador["sobres_pendientes"] || []) ++ [nuevo_sobre]
              )

            {:ok, nuevo, "Compraste un sobre #{tipo}. ID: #{nuevo_sobre["id"]}"}
          end
        end
      )
    end
  end

  # =========================
  # ABRIR SOBRE
  # =========================

  def abrir_sobre(id_o_ultimo, usuario \\ nil) do
    GestorEntrenadores.actualizar_entrenador_en_sesion(
      usuario,
      fn entrenador ->
        sobres =
          entrenador["sobres_pendientes"] || []

        sobre =
          buscar_sobre(
            sobres,
            id_o_ultimo
          )

        if sobre == nil do
          {:error, "No se encontró el sobre"}
        else
          pokemones =
            Persistencia.leer_pokemon()
            |> Enum.shuffle()
            |> Enum.take(3)
            |> Enum.map(fn especie ->
              crear_pokemon_desde_especie(
                entrenador["usuario"],
                sobre["tipo"],
                especie
              )
            end)

          nuevos_sobres =
            Enum.reject(
              sobres,
              fn s ->
                s["id"] == sobre["id"]
              end
            )

          inventario =
            entrenador["inventario"] || []

          nuevo =
            entrenador
            |> Map.put(
              "sobres_pendientes",
              nuevos_sobres
            )
            |> Map.put(
              "inventario",
              pokemones ++ inventario
            )

          {:ok, nuevo, formato_sobre_abierto(pokemones)}
        end
      end
    )
  end

  # =========================
  # CREAR POKEMON
  # =========================

  def crear_pokemon_desde_especie(
        dueno,
        tipo_sobre,
        especie
      ) do
    rareza =
      sortear_rareza(tipo_sobre)

    factor =
      sortear_factor(rareza)

    %{
      "id" => generar_id(),
      "especie" => especie["nombre"],
      "tipos" => especie["tipos"],
      "dueno_original" => dueno,
      "rareza" => rareza,
      "ataque" =>
        calcular_stat(
          especie["ataque_base"],
          factor
        ),
      "defensa" =>
        calcular_stat(
          especie["defensa_base"],
          factor
        ),
      "velocidad" =>
        calcular_stat(
          especie["velocidad_base"],
          factor
        ),
      "movimientos" => asignar_movimientos(especie["tipos"])
    }
  end

  # =========================
  # MOVIMIENTOS
  # =========================

  def asignar_movimientos(tipos) do
    movimientos =
      movimientos_planos()

    obligatorios =
      case tipos do
        [tipo] ->
          movimientos_por_tipo(tipo)
          |> Enum.take_random(2)

        [tipo1, tipo2 | _] ->
          Enum.take_random(
            movimientos_por_tipo(tipo1),
            1
          ) ++
            Enum.take_random(
              movimientos_por_tipo(tipo2),
              1
            )

        _ ->
          []
      end

    faltantes =
      4 - length(obligatorios)

    nombres_obligatorios =
      Enum.map(
        obligatorios,
        & &1["nombre"]
      )

    complementarios =
      movimientos
      |> Enum.reject(fn m ->
        m["nombre"] in nombres_obligatorios
      end)
      |> Enum.take_random(faltantes)

    obligatorios ++ complementarios
  end

  defp movimientos_planos do
    Persistencia.leer_movimientos()
    |> Enum.flat_map(fn grupo ->
      Enum.map(
        grupo["movimientos"],
        fn mov ->
          %{
            "nombre" => mov["nombre"],
            "tipo" => grupo["tipo"],
            "potencia" =>
              mov["potencia"] ||
                mov["poder_base"]
          }
        end
      )
    end)
  end

  defp movimientos_por_tipo(tipo) do
    Enum.filter(
      movimientos_planos(),
      fn m ->
        m["tipo"] == tipo
      end
    )
  end

  # =========================
  # RAREZA
  # =========================

  defp sortear_rareza(tipo_sobre) do
    probabilidades =
      @tienda[tipo_sobre]["probabilidades"]

    n =
      :rand.uniform(100)

    cond do
      n <= probabilidades["comun"] ->
        "comun"

      n <=
          probabilidades["comun"] +
            probabilidades["raro"] ->
        "raro"

      true ->
        "epico"
    end
  end

  # =========================
  # FACTORES
  # =========================

  defp sortear_factor("comun"),
    do: :rand.uniform(7) + 1

  defp sortear_factor("raro"),
    do: :rand.uniform(11) + 9

  defp sortear_factor("epico"),
    do: :rand.uniform(16) + 24

  # =========================
  # STATS
  # =========================

  defp calcular_stat(base, factor) do
    round(base * (1 + factor / 100))
  end

  # =========================
  # SOBRES
  # =========================

  defp buscar_sobre([], _),
    do: nil

  defp buscar_sobre(sobres, "ultimo"),
    do: List.last(sobres)

  defp buscar_sobre(sobres, :ultimo),
    do: List.last(sobres)

  defp buscar_sobre(sobres, id)
       when is_binary(id) do
    case Integer.parse(id) do
      {numero, ""} ->
        buscar_sobre(
          sobres,
          numero
        )

      _ ->
        nil
    end
  end

  defp buscar_sobre(sobres, id) do
    Enum.find(
      sobres,
      fn s ->
        s["id"] == id
      end
    )
  end

  # =========================
  # FORMATO
  # =========================

  defp formato_sobre_abierto(pokemones) do
    cuerpo =
      pokemones
      |> Enum.with_index(1)
      |> Enum.map(fn {p, i} ->
        movimientos =
          p["movimientos"]
          |> Enum.map(fn m ->
            "#{m["nombre"]} (#{m["potencia"]})"
          end)
          |> Enum.join(", ")

        """
        #{i}. [##{p["id"]}] #{p["especie"]}
        Tipos: #{Enum.join(p["tipos"], "/")}
        Rareza: #{p["rareza"]}
        Dueño original: #{p["dueno_original"]}
        Movimientos: #{movimientos}
        """
      end)
      |> Enum.join("\n")

    "¡Sobre abierto!\n\n" <> cuerpo
  end

  # =========================
  # UTILS
  # =========================

  defp normalizar_tipo("básico"),
    do: "basico"

  defp normalizar_tipo(tipo),
    do: String.downcase(tipo)

  defp generar_id,
    do: :rand.uniform(900_000) + 99_999
end
