defmodule ProyectoPokemon.GestorBatallas do
  alias ProyectoPokemon.{Persistencia, GestorEntrenadores}

  @fuertes %{
    "Fuego" => ["Planta", "Hielo", "Bicho"],
    "Agua" => ["Fuego", "Roca", "Tierra"],
    "Planta" => ["Agua", "Roca", "Tierra"],
    "Eléctrico" => ["Agua", "Volador"],
    "Roca" => ["Fuego", "Hielo", "Volador", "Bicho"]
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

  def atacar(atacante, defensor, movimiento) do

  dano = calcular_dano(atacante, defensor, movimiento)

  nuevo_hp = max(defensor["hp"] - dano, 0)

  defensor_actualizado =
    Map.put(defensor, "hp", nuevo_hp)

  %{
    atacante: atacante,
    defensor: defensor_actualizado,
    dano: dano
  }
end

  def calcular_dano(atacante, defensor, movimiento, factor_aleatorio \\ nil) do
    factor_aleatorio = factor_aleatorio || (85 + :rand.uniform(16) - 1) / 100
    poder = movimiento["potencia"] || movimiento["poder_base"]

    dano_base = trunc((poder * (atacante["ataque"] / defensor["defensa"])) / 5 + 2)

    dano_final =
      dano_base
      |> Kernel.*(efectividad(movimiento["tipo"], defensor["tipos"] || []))
      |> Kernel.*(stab(movimiento["tipo"], atacante["tipos"] || []))
      |> Kernel.*(factor_aleatorio)
      |> trunc()

    max(dano_final, 1)
  end

  def efectividad(tipo_movimiento, tipos_defensor) do
    Enum.reduce(tipos_defensor, 1.0, fn tipo_defensor, acc ->
      acc * modificador(tipo_movimiento, tipo_defensor)
    end)
  end

  def stab(tipo_movimiento, tipos_atacante) do
    if tipo_movimiento in tipos_atacante, do: 1.5, else: 1.0
  end

  def orden_por_velocidad(pokemon1, pokemon2) do
    cond do
      pokemon1["velocidad"] > pokemon2["velocidad"] -> [pokemon1, pokemon2]
      pokemon2["velocidad"] > pokemon1["velocidad"] -> [pokemon2, pokemon1]
      true -> Enum.shuffle([pokemon1, pokemon2])
    end
  end

  def crear_sala(tiempo_turno \\ 20) do
    iniciar_tabla_salas()
    id = "S-#{:rand.uniform(9000) + 999}"
    usuario = GestorEntrenadores.usuario_actual()

    if usuario == nil do
      {:error, "No hay sesión activa"}
    else
      sala = %{id: id, jugadores: [usuario], tiempo_turno: tiempo_turno, estado: :esperando}
      :ets.insert(:salas_batalla, {id, sala})
      {:ok, "Sala #{id} creada con tiempo de turno #{tiempo_turno}s"}
    end
  end

  def listar_salas do
    iniciar_tabla_salas()

    :ets.tab2list(:salas_batalla)
    |> Enum.map(fn {id, sala} -> "#{id} | jugadores: #{Enum.join(sala.jugadores, ", ")} | estado: #{sala.estado}" end)
    |> Enum.join("\n")
  end

  def unirse_sala(id) do
    iniciar_tabla_salas()
    usuario = GestorEntrenadores.usuario_actual()

    case :ets.lookup(:salas_batalla, id) do
      [] ->
        {:error, "La sala no existe"}

      [{^id, sala}] ->
        cond do
          usuario == nil -> {:error, "No hay sesión activa"}
          usuario in sala.jugadores -> {:error, "Ya estás en esta sala"}
          length(sala.jugadores) >= 2 -> {:error, "La sala ya está llena"}
          true ->
            nueva = %{sala | jugadores: sala.jugadores ++ [usuario]}
            :ets.insert(:salas_batalla, {id, nueva})
            {:ok, "Te uniste a la sala #{id}"}
        end
    end
  end

  def registrar_resultado(ganador, perdedor, resumen \\ "Batalla finalizada") do
    GestorEntrenadores.recompensar(ganador, perdedor)
    fecha = DateTime.utc_now() |> DateTime.to_iso8601()
    nodo = Node.self() |> Atom.to_string()
    Persistencia.registrar_batalla("#{fecha} | ganador=#{ganador} | perdedor=#{perdedor} | nodo=#{nodo} | #{resumen}")
    {:ok, "Resultado registrado. #{ganador} +100 monedas, #{perdedor} +30 monedas"}
  end

  defp modificador(tipo_movimiento, tipo_defensor) do
    cond do
      tipo_defensor in Map.get(@fuertes, tipo_movimiento, []) -> 2.0
      tipo_movimiento in Map.get(@fuertes, tipo_defensor, []) -> 0.5
      true -> 1.0
    end
  end

  defp iniciar_tabla_salas do
    if :ets.whereis(:salas_batalla) == :undefined do
      :ets.new(:salas_batalla, [:named_table, :public, :set])
    end
  end
end
