defmodule ProyectoPokemon.GestorEntrenadores do
  alias ProyectoPokemon.Persistencia

  # 🔥 SESIÓN INTERNA (ETS)
  defp iniciar_sesion(usuario) do
    if :ets.whereis(:sesion) == :undefined do
      :ets.new(:sesion, [:named_table, :public, :set])
    end

    :ets.insert(:sesion, {:usuario, usuario})
  end

  defp obtener_sesion do
    case :ets.lookup(:sesion, :usuario) do
      [{:usuario, usuario}] -> usuario
      _ -> nil
    end
  end

  # 🔥 LOGIN / REGISTRO
  def iniciar(usuario, clave) do
    trainers = Persistencia.leer_trainers()

    case buscar_usuario(trainers, usuario) do
      nil ->
        registrar_usuario(trainers, usuario, clave)

      entrenador ->
        validar_clave(entrenador, clave)
    end
  end

  # 🔥 PERFIL (con sesión automática)
  def perfil(usuario \\ nil) do
    usuario =
      if usuario == nil do
        obtener_sesion()
      else
        usuario
      end

    if usuario == nil do
      IO.puts("No hay sesión activa")
    else
      trainers = Persistencia.leer_trainers()

      case buscar_usuario(trainers, usuario) do
        nil ->
          IO.puts("Usuario no existe")

        entrenador ->
          IO.puts("=== Perfil de #{usuario} ===")
          IO.puts("Monedas: #{entrenador["monedas"]}")
          IO.puts("Victorias: #{entrenador["victorias"]}")
      end
    end
  end

  # 🔒 PRIVADOS
  defp buscar_usuario(trainers, usuario) do
    Enum.find(trainers, fn t -> t["usuario"] == usuario end)
  end

  defp registrar_usuario(trainers, usuario, clave) do
    nuevo = %{
      "usuario" => usuario,
      "clave" => clave,
      "monedas" => 100,
      "victorias" => 0
    }

    Persistencia.guardar_trainers([nuevo | trainers])

    # 🔥 sesión automática
    iniciar_sesion(usuario)

    {:ok, "Usuario registrado correctamente"}
  end

  defp validar_clave(entrenador, clave) do
    if entrenador["clave"] == clave do
      # 🔥 sesión automática
      iniciar_sesion(entrenador["usuario"])

      {:ok, "Inicio de sesión exitoso"}
    else
      {:error, "Clave incorrecta"}
    end
  end
end
