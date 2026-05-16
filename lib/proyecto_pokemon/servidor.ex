defmodule ProyectoPokemon.Servidor do
  alias ProyectoPokemon.{
    GestorEntrenadores,
    GestorSobres,
    GestorSalas
  }

  # =========================
  # ENTRADA PRINCIPAL
  # =========================

  def ejecutar(comando) when is_binary(comando) do
    comando
    |> String.trim()
    |> String.split(" ", trim: true)
    |> interpretar()
  end

  def ejecutar(_comando) do
    {:error, "El comando debe ser texto"}
  end

  # =========================
  # ENTRENADORES
  # =========================

  defp interpretar(["iniciar", usuario, clave]) do
    GestorEntrenadores.iniciar(usuario, clave)
  end

  defp interpretar(["salir"]) do
    GestorEntrenadores.salir()
  end

  defp interpretar(["perfil"]) do
    GestorEntrenadores.perfil()
  end

  defp interpretar(["inventario"]) do
    GestorEntrenadores.inventario()
  end

  defp interpretar(["clasificacion"]) do
    GestorEntrenadores.clasificacion()
  end

  # =========================
  # SOBRES
  # =========================

  defp interpretar(["tienda"]) do
    GestorSobres.tienda()
  end

  defp interpretar(["comprar_sobre", tipo]) do
    GestorSobres.comprar_sobre(tipo)
  end

  defp interpretar(["abrir_sobre", id]) do
    GestorSobres.abrir_sobre(id)
  end

  # =========================
  # EQUIPOS
  # =========================

  defp interpretar(["crear_equipo", nombre, ids]) do
    GestorEntrenadores.crear_equipo(nombre, ids)
  end

  defp interpretar(["listar_equipos"]) do
    GestorEntrenadores.listar_equipos()
  end

  defp interpretar(["usar_equipo", nombre]) do
    GestorEntrenadores.usar_equipo(nombre)
  end

  # =========================
  # SALAS DE BATALLA
  # =========================

  defp interpretar(["crear_sala"]) do
    GestorSalas.crear_sala()
  end

  defp interpretar(["crear_sala", "tiempo_turno=" <> segundos]) do
    crear_sala_con_tiempo(segundos)
  end

  defp interpretar(["listar_salas"]) do
    GestorSalas.listar_salas()
  end

  defp interpretar(["unirse_sala", id]) do
    GestorSalas.unirse_sala(id)
  end

  defp interpretar(["salir_sala", id]) do
    GestorSalas.salir_sala(id)
  end

  defp interpretar(["obtener_sala", id]) do
    GestorSalas.obtener_sala(id)
  end

  defp interpretar(["eliminar_sala", id]) do
    GestorSalas.eliminar_sala(id)
  end

  # =========================
  # BATALLAS
  # =========================
  # Esta parte se deja preparada, pero no se activa todavía
  # porque iniciar_batalla depende de cómo terminen de implementar
  # GestorBatallas y MotorBatalla.
  #
  # defp interpretar(["iniciar_batalla", id_sala]) do
  #   GestorBatallas.iniciar_batalla(id_sala)
  # end

  # =========================
  # COMANDOS VACÍOS O INVÁLIDOS
  # =========================

  defp interpretar([]) do
    {:error, "No ingresaste ningún comando"}
  end

  defp interpretar(_comando) do
    {:error, "Comando no reconocido"}
  end

  # =========================
  # FUNCIONES AUXILIARES
  # =========================

  defp crear_sala_con_tiempo(segundos) do
    case Integer.parse(segundos) do
      {tiempo_turno, ""} when tiempo_turno > 0 ->
        GestorSalas.crear_sala(tiempo_turno)

      _ ->
        {:error, "El tiempo de turno debe ser un número entero positivo"}
    end
  end
end
