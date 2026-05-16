defmodule ProyectoPokemon.MenuInicio do
  def iniciar do
    mostrar_menu()
  end

  defp mostrar_menu do
    IO.puts("""
    1. Iniciar sesión
    2. Registrarse
    """)

    case IO.gets("> ") |> String.trim() do
      "1" -> ProyectoPokemon.MenuLogin.iniciar()
      "2" -> registro()
      _ -> mostrar_menu()
    end
  end

  defp registro do
    usuario = IO.gets("Nuevo usuario: ") |> String.trim()
    clave = IO.gets("Clave: ") |> String.trim()

    case ProyectoPokemon.Servidor.ejecutar("iniciar " <> usuario <> " " <> clave) do
      {:ok, msg} ->
        IO.puts(msg)
        mostrar_menu()

      {:error, msg} ->
        IO.puts(msg)
        mostrar_menu()
    end
  end
end
