defmodule ProyectoPokemon.MenuLogin do

  alias ProyectoPokemon.Servidor

  def iniciar do
    mostrar_menu()
  end

  defp mostrar_menu do
    IO.puts("""
    1. Iniciar sesión
    2. Volver
    """)

    case IO.gets("> ") |> String.trim() do
      "1" -> login()
      "2" -> ProyectoPokemon.MenuInicio.iniciar()
      _ -> mostrar_menu()
    end
  end

  defp login do
    usuario = IO.gets("Usuario: ") |> String.trim()
    clave = IO.gets("Clave: ") |> String.trim()

    case Servidor.ejecutar("iniciar " <> usuario <> " " <> clave) do
      {:ok, msg} ->
        IO.puts(msg)
        ProyectoPokemon.MenuPrincipal.iniciar()

      {:error, msg} ->
        IO.puts(msg)
        mostrar_menu()
    end
  end

end
