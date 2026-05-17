defmodule ProyectoPokemon.GestorEntrenadores do
  alias ProyectoPokemon.Persistencia

  # =====================================================
  # SESIÓN (ETS)
  # =====================================================

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

  # =====================================================
  # AUTH
  # =====================================================

  def iniciar(usuario, clave) do
    trainers = Persistencia.leer_trainers()

    case buscar_usuario(trainers, usuario) do
      nil -> registrar_usuario(trainers, usuario, clave)
      entrenador -> validar_clave(entrenador, clave)
    end
  end

  # =====================================================
  # SESIÓN ACTUAL
  # =====================================================

  # FIX: extraído como helper reutilizable; evita repetir leer_trainers()
  # en cada función pública.
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

  # =====================================================
  # PERFIL
  # =====================================================

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

  # =====================================================
  # INVENTARIO
  # =====================================================

  # FIX: eliminado el defmodule anidado que existía aquí (bug crítico de compilación)
  def inventario(usuario \\ nil) do
    with {:ok, entrenador} <- entrenador_en_sesion(usuario) do
      inventario = entrenador["inventario"] || []

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
           Ataque: #{p["ataque"]} | Defensa: #{p["defensa"]} | Velocidad: #{p["velocidad"]}
           Dueño: #{p["dueno_original"]}
           Movimientos: #{movimientos}
        """
      end)
      |> Enum.join("\n")
    end
  end

  # =====================================================
  # CLASIFICACIÓN
  # =====================================================

  def clasificacion do
    Persistencia.leer_trainers()
    |> Enum.sort_by(&{-&1["victorias"], -&1["monedas_acumuladas"]})
    |> Enum.with_index(1)
    |> Enum.map(fn {e, i} ->
      "#{i}. #{e["usuario"]} | Victorias: #{e["victorias"]} | Monedas: #{e["monedas_acumuladas"]}"
    end)
    |> Enum.join("\n")
    |> then(&("=== Clasificación Global ===\n" <> &1))
  end

  # =====================================================
  # EQUIPOS
  # =====================================================

  def crear_equipo(nombre, ids_texto, usuario \\ nil) do
    # FIX: parsear_ids ahora devuelve {:ok, ids} | {:error, msg}
    case parsear_ids(ids_texto) do
      {:error, msg} ->
        {:error, msg}

      {:ok, ids} when length(ids) < 1 or length(ids) > 3 ->
        {:error, "El equipo debe tener entre 1 y 3 Pokémon"}

      {:ok, ids} ->
        actualizar_entrenador_en_sesion(usuario, fn entrenador ->
          inventario_ids = Enum.map(entrenador["inventario"] || [], & &1["id"])
          equipos = entrenador["equipos"] || %{}

          cond do
            Map.has_key?(equipos, nombre) ->
              {:error, "Ya existe ese equipo"}

            Enum.any?(ids, fn id -> id not in inventario_ids end) ->
              {:error, "Faltan Pokémon en inventario"}

            true ->
              nuevos_equipos = Map.put(equipos, nombre, ids)
              nuevo_entrenador = Map.put(entrenador, "equipos", nuevos_equipos)
              {:ok, nuevo_entrenador, "Equipo creado correctamente"}
          end
        end)
    end
  end

  def listar_equipos(usuario \\ nil) do
    with {:ok, e} <- entrenador_en_sesion(usuario) do
      equipos = e["equipos"] || %{}

      if map_size(equipos) == 0 do
        "No tienes equipos"
      else
        equipos
        |> Enum.map(fn {n, ids} ->
          "#{n} [#{length(ids)}]: #{Enum.join(ids, ", ")}"
        end)
        |> Enum.join("\n")
      end
    end
  end

  def usar_equipo(nombre, usuario \\ nil) do
    actualizar_entrenador_en_sesion(usuario, fn entrenador ->
      equipos = entrenador["equipos"] || %{}
      ids = Map.get(equipos, nombre)
      inventario_ids = Enum.map(entrenador["inventario"] || [], & &1["id"])

      cond do
        ids == nil ->
          {:error, "No existe ese equipo"}

        Enum.any?(ids, fn id -> id not in inventario_ids end) ->
          {:error, "Faltan Pokémon para usar equipo"}

        true ->
          nuevo = Map.put(entrenador, "equipo_actual", nombre)
          {:ok, nuevo, "Equipo cargado"}
      end
    end)
  end

  # =====================================================
  # ACTUALIZACIÓN
  # =====================================================

  def actualizar_entrenador(usuario, funcion) do
    trainers = Persistencia.leer_trainers()

    nuevos =
      Enum.map(trainers, fn e ->
        if e["usuario"] == usuario, do: funcion.(e), else: e
      end)

    Persistencia.guardar_trainers(nuevos)
    {:ok, "Actualizado"}
  end

  # FIX: indentación y end correctamente dentro del módulo
  def actualizar_entrenador_en_sesion(usuario, funcion) do
    with {:ok, entrenador} <- entrenador_en_sesion(usuario) do
      case funcion.(entrenador) do
        {:ok, nuevo, mensaje} ->
          # FIX: una sola lectura de trainers aquí, no doble
          trainers = Persistencia.leer_trainers()

          nuevos_trainers =
            Enum.map(trainers, fn e ->
              if e["usuario"] == nuevo["usuario"], do: nuevo, else: e
            end)

          Persistencia.guardar_trainers(nuevos_trainers)
          {:ok, mensaje}

        {:error, mensaje} ->
          {:error, mensaje}
      end
    end
  end

  def recompensar(ganador, perdedor) do
    actualizar_entrenador(ganador, fn e ->
      e
      |> Map.update("monedas", 0, &(&1 + 100))
      |> Map.update("monedas_acumuladas", 0, &(&1 + 100))
      |> Map.update("victorias", 0, &(&1 + 1))
    end)

    actualizar_entrenador(perdedor, fn e ->
      e
      |> Map.update("monedas", 0, &(&1 + 30))
      |> Map.update("monedas_acumuladas", 0, &(&1 + 30))
    end)
  end

  def buscar_entrenador(usuario) do
    Persistencia.leer_trainers()
    |> Enum.find(&(&1["usuario"] == usuario))
  end

  # =====================================================
  # HELPERS
  # =====================================================

  defp buscar_usuario(trainers, usuario),
    do: Enum.find(trainers, &(&1["usuario"] == usuario))

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
    {:ok, "Usuario creado"}
  end

  defp validar_clave(entrenador, clave) do
    if entrenador["clave"] == clave do
      iniciar_sesion(entrenador["usuario"])
      {:ok, "Login correcto"}
    else
      {:error, "Clave incorrecta"}
    end
  end

  # FIX: manejo seguro de entradas no numéricas con try/rescue
  defp parsear_ids(ids_texto) when is_binary(ids_texto) do
    try do
      ids =
        ids_texto
        |> String.split(",", trim: true)
        |> Enum.map(&(String.trim(&1) |> String.to_integer()))

      {:ok, ids}
    rescue
      ArgumentError -> {:error, "IDs inválidos: asegúrate de ingresar números separados por coma"}
    end
  end

  defp parsear_ids(ids) when is_list(ids), do: {:ok, ids}

  defp generar_id do
    :rand.uniform(900_000) + 99_999
  end
end
