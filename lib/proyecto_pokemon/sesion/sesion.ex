defmodule ProyectoPokemon.Sesion do
  @tabla :sesion

  def init do
    if :ets.whereis(@tabla) == :undefined do
      :ets.new(@tabla, [:named_table, :public, :set])
    end
  end

  def iniciar(usuario) do
    init()
    :ets.insert(@tabla, {:usuario, usuario})
  end

  def actual do
    init()

    case :ets.lookup(@tabla, :usuario) do
      [{:usuario, u}] -> u
      _ -> nil
    end
  end

  def cerrar do
    :ets.delete(@tabla, :usuario)
    {:ok, "Sesión cerrada"}
  end
end
