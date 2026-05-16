defmodule ProyectoPokemon.GestorSalasTest do
  use ExUnit.Case

  alias ProyectoPokemon.GestorSalas

  setup do

    start_supervised!(GestorSalas)

    :ok
  end

  test "crear una sala" do

    {:ok, mensaje} =
      GestorSalas.crear_sala()

    assert mensaje =~ "Sala creada"
  end

  test "listar salas" do

    GestorSalas.crear_sala()

    salas = GestorSalas.listar_salas()

    assert length(salas) > 0
  end
end
