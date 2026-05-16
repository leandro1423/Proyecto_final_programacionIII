defmodule ProyectoPokemon.CLI do
  def iniciar do
    Node.self()
    |> Atom.to_string()
    |> iniciar_segun_nodo()
  end

  # Si el nodo se llama servidor@..., abre menú administrativo.
  defp iniciar_segun_nodo("servidor@" <> _host) do
    ProyectoPokemon.MenuServidor.iniciar()
  end

  # Cualquier otro nodo se considera cliente.
  defp iniciar_segun_nodo(_otro_nodo) do
    conectar_con_servidor()
    ProyectoPokemon.MenuInicio.iniciar()
  end

  defp conectar_con_servidor do
    IO.puts("""

    ============================
      CONEXIÓN AL SERVIDOR
    ============================

    Escribe el nodo del servidor.

    Ejemplos:
    - servidor@MHAPAS
    - servidor@PCJUAN
    - servidor@PORTATILPROFE

    Si estás probando en el mismo computador,
    normalmente será: servidor@#{host_actual()}
    """)

    entrada =
      IO.gets("Nodo servidor: ")
      |> String.trim()

    conectar_nodo(entrada)
  end

  defp conectar_nodo("") do
    nodo_por_defecto =
      "servidor@#{host_actual()}"
      |> String.to_atom()

    intentar_conexion(nodo_por_defecto)
  end

  defp conectar_nodo(nombre_servidor) do
    nombre_servidor
    |> String.to_atom()
    |> intentar_conexion()
  end

  defp intentar_conexion(nodo_servidor) do
    cond do
      nodo_servidor in Node.list() ->
        IO.puts("\nYa estás conectado a #{nodo_servidor}.\n")

      Node.connect(nodo_servidor) ->
        IO.puts("\nConexión exitosa con #{nodo_servidor}.\n")

      true ->
        IO.puts("""

        No fue posible conectar con #{nodo_servidor}.

        Revisa:
        1. Que el servidor esté encendido.
        2. Que ambos usen la misma cookie.
        3. Que el nombre del nodo esté bien escrito.
        4. Que estén en la misma red.
        5. Que el firewall no esté bloqueando Erlang/Elixir.
        """)
    end
  end

  defp host_actual do
    Node.self()
    |> Atom.to_string()
    |> String.split("@")
    |> obtener_host()
  end

  defp obtener_host([_nombre, host]), do: host
  defp obtener_host(_), do: "NOMBRE_DEL_PC"
end
