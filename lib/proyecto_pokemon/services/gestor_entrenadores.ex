defmodule ProyectoPokemon.GestorEntrenadores do
  alias ProyectoPokemon.Persistencia

  defp tabla_sesion do
    if :ets.whereis(:sesion) == :undefined do
      :ets.new(:sesion, [:named_table, :public, :set])
    end

    :sesion
  end

  defp iniciar_sesion(usuario) do
    :ets.insert(tabla_sesion(), {:usuario, usuario})
  end

  def usuario_actual do
    case :ets.lookup(tabla_sesion(), :usuario) do
      [{:usuario, usuario}] -> usuario
      _ -> nil
    end
  end

  def salir do
    :ets.delete(tabla_sesion(), :usuario)
    {:ok, "Sesión cerrada"}
  end

  def iniciar(usuario, clave) do
    trainers = Persistencia.leer_trainers()

    case buscar_usuario(trainers, usuario) do
      nil -> registrar_usuario(trainers, usuario, clave)
      entrenador -> validar_clave(entrenador, clave)
    end
  end

  def perfil(usuario \\ nil) do
    with {:ok, entrenador} <- entrenador_en_sesion(usuario) do
      inventario = entrenador["inventario"] || []
      sobres = entrenador["sobres_pendientes"] || []

      """
      === Perfil de #{entrenador["usuario"]} ===
      Monedas: #{entrenador["monedas"]}
      Monedas acumuladas: #{entrenador["monedas_acumuladas"]}
      Victorias: #{entrenador["victorias"]}
      Sobres pendientes: #{length(sobres)}
      Pokémon en inventario: #{length(inventario)}
      """
    end
  end

  def inventario(usuario \\ nil) do
    with {:ok, entrenador} <- entrenador_en_sesion(usuario) do
      inventario = entrenador["inventario"] || []

      cuerpo =
        inventario
        |> Enum.with_index(1)
        |> Enum.map(fn {p, i} ->
          movimientos =
            (p["movimientos"] || [])
            |> Enum.map(fn m -> "#{m["nombre"]}(#{m["potencia"] || m["poder_base"]})" end)
            |> Enum.join(", ")

          tipos = p["tipos"] || []

          """
            #{i}. [##{p["id"]}] #{p["especie"]} (#{Enum.join(tipos, "/")}) [#{p["rareza"]}]
               Ataque: #{p["ataque"]} | Defensa: #{p["defensa"]} | Velocidad: #{p["velocidad"]} | Salud máx: 100
               Dueño original: #{p["dueno_original"]}
               Movimientos: #{movimientos}
          """
        end)
        |> Enum.join("\n")

      "=== Inventario de #{entrenador["usuario"]} (#{length(inventario)} Pokémon) ===\n" <> cuerpo
    end
  end

  def clasificacion do
    Persistencia.leer_trainers()
    |> Enum.sort_by(fn e -> {-e["victorias"], -e["monedas_acumuladas"]} end)
    |> Enum.with_index(1)
    |> Enum.map(fn {e, i} ->
      "#{i}. #{e["usuario"]} | Victorias: #{e["victorias"]} | Monedas acumuladas: #{e["monedas_acumuladas"]}"
    end)
    |> Enum.join("\n")
    |> then(&("=== Clasificación Global ===\n" <> &1))
  end

  def crear_equipo(nombre, ids_texto, usuario \\ nil) do
    ids = parsear_ids(ids_texto)

    cond do
      length(ids) < 1 or length(ids) > 3 ->
        {:error, "El equipo debe tener entre 1 y 3 Pokémon"}

      true ->
        actualizar_entrenador_en_sesion(usuario, fn entrenador ->
          inventario_ids = Enum.map(entrenador["inventario"] || [], & &1["id"])
          faltantes = Enum.reject(ids, &(&1 in inventario_ids))
          equipos = entrenador["equipos"] || %{}

          cond do
            Map.has_key?(equipos, nombre) ->
              {:error, "Ya existe un equipo con ese nombre"}

            faltantes != [] ->
              {:error, "No tienes estos Pokémon en inventario: #{Enum.join(faltantes, ", ")}"}

            true ->
              nuevo = Map.put(entrenador, "equipos", Map.put(equipos, nombre, ids))
              {:ok, nuevo, "Equipo #{nombre} creado correctamente"}
          end
        end)
    end
  end

  def listar_equipos(usuario \\ nil) do
    with {:ok, entrenador} <- entrenador_en_sesion(usuario) do
      equipos = entrenador["equipos"] || %{}

      if map_size(equipos) == 0 do
        "No tienes equipos guardados"
      else
        cuerpo =
          equipos
          |> Enum.map(fn {nombre, ids} -> "#{nombre} [#{length(ids)}/3]: #{Enum.join(ids, ", ")}" end)
          |> Enum.join("\n")

        "Equipos guardados:\n" <> cuerpo
      end
    end
  end

  def usar_equipo(nombre, usuario \\ nil) do
    actualizar_entrenador_en_sesion(usuario, fn entrenador ->
      equipos = entrenador["equipos"] || %{}
      ids = equipos[nombre]
      inventario_ids = Enum.map(entrenador["inventario"] || [], & &1["id"])

      cond do
        ids == nil ->
          {:error, "No existe un equipo con ese nombre"}

        Enum.any?(ids, fn id -> id not in inventario_ids end) ->
          faltantes = Enum.reject(ids, &(&1 in inventario_ids))
          {:error, "No puedes usar el equipo. Faltan Pokémon: #{Enum.join(faltantes, ", ")}"}

        true ->
          {:ok, Map.put(entrenador, "equipo_actual", nombre), "Equipo #{nombre} cargado para batalla"}
      end
    end)
  end

  def agregar_pokemon(usuario, pokemon) do
    actualizar_entrenador(usuario, fn entrenador ->
      inventario = entrenador["inventario"] || []
      Map.put(entrenador, "inventario", [pokemon | inventario])
    end)
  end

  def actualizar_entrenador(usuario, funcion) do
    trainers = Persistencia.leer_trainers()

    nuevos =
      Enum.map(trainers, fn e ->
        if e["usuario"] == usuario, do: funcion.(e), else: e
      end)

    Persistencia.guardar_trainers(nuevos)
    {:ok, buscar_usuario(nuevos, usuario)}
  end

  def actualizar_entrenador_en_sesion(usuario, funcion) do
    with {:ok, entrenador} <- entrenador_en_sesion(usuario) do
      case funcion.(entrenador) do
        {:ok, nuevo_entrenador, mensaje} ->
          trainers = Persistencia.leer_trainers()
          nuevos = reemplazar_entrenador(trainers, nuevo_entrenador)
          Persistencia.guardar_trainers(nuevos)
          {:ok, mensaje}

        {:error, mensaje} ->
          {:error, mensaje}
      end
    end
  end

  def recompensar(ganador, perdedor) do
    actualizar_entrenador(ganador, fn e ->
      e
      |> Map.put("monedas", e["monedas"] + 100)
      |> Map.put("monedas_acumuladas", e["monedas_acumuladas"] + 100)
      |> Map.put("victorias", e["victorias"] + 1)
    end)

    actualizar_entrenador(perdedor, fn e ->
      e
      |> Map.put("monedas", e["monedas"] + 30)
      |> Map.put("monedas_acumuladas", e["monedas_acumuladas"] + 30)
    end)
  end

  defp entrenador_en_sesion(usuario) do
    usuario = usuario || usuario_actual()

    if usuario == nil do
      {:error, "No hay sesión activa"}
    else
      case buscar_usuario(Persistencia.leer_trainers(), usuario) do
        nil -> {:error, "Usuario no existe"}
        entrenador -> {:ok, entrenador}
      end
    end
  end

  defp registrar_usuario(trainers, usuario, clave) do
    nuevo = %{
      "usuario" => usuario,
      "clave" => clave,
      "monedas" => 0,
      "monedas_acumuladas" => 0,
      "victorias" => 0,
      "sobres_pendientes" => [%{"id" => generar_id(), "tipo" => "basico"}],
      "inventario" => [],
      "equipos" => %{},
      "equipo_actual" => nil
    }

    Persistencia.guardar_trainers([nuevo | trainers])
    iniciar_sesion(usuario)
    {:ok, "Usuario registrado correctamente. Recibiste 1 sobre básico gratis"}
  end

  defp validar_clave(entrenador, clave) do
    if entrenador["clave"] == clave do
      iniciar_sesion(entrenador["usuario"])
      {:ok, "Inicio de sesión exitoso"}
    else
      {:error, "Clave incorrecta"}
    end
  end

  defp buscar_usuario(trainers, usuario), do: Enum.find(trainers, fn t -> t["usuario"] == usuario end)

  defp reemplazar_entrenador(trainers, entrenador) do
    Enum.map(trainers, fn e -> if e["usuario"] == entrenador["usuario"], do: entrenador, else: e end)
  end

  defp parsear_ids(ids_texto) when is_binary(ids_texto) do
    ids_texto
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_integer/1)
  end

  defp parsear_ids(ids) when is_list(ids), do: ids

  defp generar_id, do: :rand.uniform(900_000) + 99_999
end
