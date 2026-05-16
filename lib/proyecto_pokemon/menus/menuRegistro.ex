defmodule ProyectoPokemon.MenuRegistro do
  alias ProyectoPokemon.Servidor

  def iniciar do
    registro()
  end

  defp registro do
    usuario = IO.gets("Usuario: ") |> String.trim()
    clave = IO.gets("Clave: ") |> String.trim()

    case Servidor.ejecutar("iniciar " <> usuario <> " " <> clave) do
      {:ok, msg} ->
        IO.puts(msg)
        :ok

      {:error, msg} ->
        IO.puts(msg)
        registro()
    end
  end
end
