defmodule ProyectoPokemon.MenuPrincipal do

  def iniciar do
    mostrar_menu()
  end

  defp mostrar_menu do
    IO.puts("""
    =====================
      MENU PRINCIPAL
    =====================

    1. Batallas
    2. Perfil
    3. Inventario
    4. Cerrar sesión
    """)

    case IO.gets("> ") |> String.trim() do
      "1" -> IO.puts("Batallas")
      "2" -> IO.puts("Perfil")
      "3" -> IO.puts("Inventario")
      "4" -> IO.puts("Saliendo...")
      _ -> mostrar_menu()
    end
  end

end
