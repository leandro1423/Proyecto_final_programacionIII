defmodule ProyectoPokemon.GestorSalas do
  use GenServer

  alias ProyectoPokemon.{
    GestorEntrenadores,
    GestorBatallas
  }

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

  def salir_sala(id) do
    usuario = GestorEntrenadores.usuario_actual()

    GenServer.call(
      {:global, :gestor_salas},
      {:salir_sala, id, usuario}
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
  def handle_call(:listar_salas, _from, estado) do
    {:reply, Map.values(estado), estado}
  end

  @impl true
  def handle_call({:crear_sala, usuario}, from, estado) do
    handle_call({:crear_sala, usuario, 20}, from, estado)
  end

  @impl true
  def handle_call({:crear_sala, usuario, tiempo_turno}, _from, estado) do
    id = "S-" <> Integer.to_string(:rand.uniform(9999))

    nueva_sala = %{
      id: id,
      creador: usuario || "invitado",

      jugadores: [usuario || "invitado"],

      estado: :esperando,

      tiempo_turno: tiempo_turno,

      turno_actual: nil,

      jugador1: nil,

      jugador2: nil,

      ganador: nil
    }

    nuevo_estado =
      Map.put(estado, id, nueva_sala)

    {:reply, {:ok, "Sala creada con ID #{id}"}, nuevo_estado}
  end

  @impl true
  def handle_call({:unirse_sala, id, usuario}, _from, estado) do
    case Map.get(estado, id) do
      nil ->
        {:reply, {:error, "La sala no existe"}, estado}

      sala ->
        cond do
          usuario in sala.jugadores ->
            {:reply, {:error, "Ya estás en la sala"}, estado}

          length(sala.jugadores) >= 2 ->
            {:reply, {:error, "La sala está llena"}, estado}

          true ->
            nuevos_jugadores =
              sala.jugadores ++ [usuario]

            nueva_sala = %{
              sala
              | jugadores: nuevos_jugadores,
                estado: :en_batalla,

                turno_actual: List.first(nuevos_jugadores),

                jugador1: %{
                  usuario: Enum.at(nuevos_jugadores, 0),
                  pokemon_activo: 0,
                  equipo: []
                },

                jugador2: %{
                  usuario: Enum.at(nuevos_jugadores, 1),
                  pokemon_activo: 0,
                  equipo: []
                }
            }

            nuevo_estado =
              Map.put(estado, id, nueva_sala)


            {:reply, {:ok, "#{usuario} se unió a la sala"}, nuevo_estado}
        end
    end
  end

  @impl true
  def handle_call({:obtener_sala, id}, _from, estado) do
    {:reply, Map.get(estado, id), estado}
  end

  @impl true
  def handle_call({:salir_sala, id, usuario}, _from, estado) do
    case Map.get(estado, id) do
      nil ->
        {:reply, {:error, "La sala no existe"}, estado}

      sala ->
        if usuario in sala.jugadores do
          restantes =
            Enum.reject(sala.jugadores, fn j -> j == usuario end)

          es_1v1 = length(sala.jugadores) == 2

          {nuevo_estado, mensaje} =
            if es_1v1 do
              ganador = List.first(restantes)

              GestorBatallas.registrar_resultado(
                ganador,
                usuario,
                "Abandono de sala"
              )

              {
                Map.delete(estado, id),
                "#{usuario} abandonó la sala. #{ganador} gana automáticamente"
              }
            else
              nueva_sala = %{
                sala
                | jugadores: restantes,
                  estado: :esperando
              }

              {
                Map.put(estado, id, nueva_sala),
                "#{usuario} salió de la sala"
              }
            end

          {:reply, {:ok, mensaje}, nuevo_estado}
        else
          {:reply, {:error, "No perteneces a esa sala"}, estado}
        end
    end
  end
end
