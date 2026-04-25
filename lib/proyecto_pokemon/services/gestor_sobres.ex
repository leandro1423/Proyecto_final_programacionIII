defmodule GestorSobres do

  @moduledoc """
  Módulo encargado de la lógica de sobres.
  """

  @doc """
  Asigna Pokémon a un entrenador (lógica pendiente).
  """
  def asignar_pokemon(entrenador) when is_map(entrenador) do
    entrenador
  end

  def asignar_pokemon(_), do: {:error, "Entrenador inválido"}


  @doc """
  Asigna movimientos a una lista de Pokémon (lógica pendiente).
  """
  def asignar_movimientos(pokemones) when is_list(pokemones) do
    pokemones
  end

  def asignar_movimientos(_), do: {:error, "Lista inválida"}


  @doc """
  Valida si el entrenador tiene suficientes monedas.
  """
  def validar_monedas(entrenador) when is_map(entrenador) do
    # por ahora devolvemos true (lógica futura)
    true
  end

  def validar_monedas(_), do: {:error, "Entrenador inválido"}

end
