defmodule ProyectoPokemon.CLI do
  def iniciar do
    Node.self()
    |> Atom.to_string()
    |> iniciar_segun_nodo()
  end

  # Si el nodo se llama servidor@..., abre el menú administrativo.
  defp iniciar_segun_nodo("servidor@" <> _host) do
    ProyectoPokemon.MenuServidor.iniciar()
  end

  # Cualquier otro nodo se considera cliente.
  defp iniciar_segun_nodo(_otro_nodo) do
    conectar_servidor_si_es_posible()
    ProyectoPokemon.MenuInicio.iniciar()
  end

  # =========================
  # CONEXIÓN AUTOMÁTICA OPCIONAL
  # =========================

  defp conectar_servidor_si_es_posible do
    servidor = nodo_servidor()

    case servidor do
      nil ->
        IO.puts("""
        No se pudo deducir automáticamente el nodo servidor.

        Si estás en un cliente, conecta manualmente con:
        Node.connect(:servidor@NOMBRE_DEL_HOST)
        """)

      nodo ->
        conectar_servidor(nodo)
    end
  end

  defp nodo_servidor do
    case Node.self() do
      :nonode@nohost ->
        nil

      nodo ->
        nodo
        |> Atom.to_string()
        |> construir_nodo_servidor()
    end
  end

  defp construir_nodo_servidor(nombre_nodo) do
    case String.split(nombre_nodo, "@") do
      [_nombre_cliente, host] ->
        String.to_atom("servidor@" <> host)

      _ ->
        nil
    end
  end

  defp conectar_servidor(nil), do: :ok

  defp conectar_servidor(nodo_servidor) do
    cond do
      nodo_servidor in Node.list() ->
        IO.puts("Cliente conectado al servidor #{nodo_servidor}")

      Node.connect(nodo_servidor) ->
        IO.puts("Conexión exitosa con #{nodo_servidor}")

      true ->
        IO.puts("""
        No fue posible conectar con #{nodo_servidor}.

        Asegúrate de tener abierto el servidor con:
        iex.bat --sname servidor --cookie pokemon -S mix
        """)
    end
  end
end
