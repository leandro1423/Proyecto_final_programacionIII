defmodule ProyectoPokemon.GestorSalas do
  use GenServer

  alias ProyectoPokemon.GestorEntrenadores

  # =========================
  # CLIENTE
  # =========================

  def start_link(_opts) do
    GenServer.start_link(
      __MODULE__,
      %{},
      name: {:global, :gestor_salas}
    )
  end

  def crear_sala(tiempo_turno \\ 20) do
    usuario = GestorEntrenadores.usuario_actual()

    GenServer.call(
      {:global, :gestor_salas},
      {:crear_sala, usuario, tiempo_turno}
    )
  end

  def listar_salas do
    GenServer.call(
      {:global, :gestor_salas},
      :listar_salas
    )
  end

  def unirse_sala(id) do
    usuario = GestorEntrenadores.usuario_actual()

    GenServer.call(
      {:global, :gestor_salas},
      {:unirse_sala, id, usuario}
    )
  end

  def obtener_sala(id) do
    GenServer.call(
      {:global, :gestor_salas},
      {:obtener_sala, id}
    )
  end

  def eliminar_sala(id) do
    GenServer.call(
      {:global, :gestor_salas},
      {:eliminar_sala, id}
    )
  end

  # =========================
  # SERVER
  # =========================

  @impl true
  def init(estado) do
    {:ok, estado}
  end

  @impl true
  def handle_call(
        {:crear_sala, usuario, tiempo_turno},
        _from,
        estado
      ) do

    if usuario == nil do
      {:reply, {:error, "No hay sesión activa"}, estado}
    else
      id = "S-#{:rand.uniform(9000) + 999}"

      sala = %{
        id: id,
        jugadores: [usuario],
        tiempo_turno: tiempo_turno,
        estado: :esperando
      }

      nuevo_estado =
        Map.put(estado, id, sala)

      {:reply,
       {:ok, "Sala #{id} creada"},
       nuevo_estado}
    end
  end

  @impl true
  def handle_call(:listar_salas, _from, estado) do
    salas =
      estado
      |> Enum.map(fn {id, sala} ->
        "#{id} | jugadores: #{Enum.join(sala.jugadores, ", ")} | estado: #{sala.estado}"
      end)
      |> Enum.join("\n")

    {:reply, salas, estado}
  end

  @impl true
  def handle_call(
        {:unirse_sala, id, usuario},
        _from,
        estado
      ) do

    case Map.get(estado, id) do
      nil ->
        {:reply, {:error, "La sala no existe"}, estado}

      sala ->
        cond do
          usuario == nil ->
            {:reply, {:error, "No hay sesión activa"}, estado}

          usuario in sala.jugadores ->
            {:reply, {:error, "Ya estás en esta sala"}, estado}

          length(sala.jugadores) >= 2 ->
            {:reply, {:error, "La sala ya está llena"}, estado}

          true ->
            nueva_sala = %{
              sala |
              jugadores: sala.jugadores ++ [usuario],
              estado: :lista
            }

            nuevo_estado =
              Map.put(estado, id, nueva_sala)

            {:reply,
             {:ok, "Te uniste a la sala #{id}"},
             nuevo_estado}
        end
    end
  end

  @impl true
  def handle_call({:obtener_sala, id}, _from, estado) do
    case Map.get(estado, id) do
      nil ->
        {:reply, {:error, "Sala no encontrada"}, estado}

      sala ->
        {:reply, {:ok, sala}, estado}
    end
  end

  @impl true
  def handle_call({:eliminar_sala, id}, _from, estado) do
    nuevo_estado =
      Map.delete(estado, id)

    {:reply,
     {:ok, "Sala eliminada"},
     nuevo_estado}
  end
end
