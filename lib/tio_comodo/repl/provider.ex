defmodule TioComodo.Repl.Provider do
  @moduledoc """
  A provider that fetches commands from a user-defined function.
  """

  @behaviour TioComodo.Repl.Provider.Behaviour

  @impl TioComodo.Repl.Provider.Behaviour
  def dispatch(input) do
    with {:ok, command_map} <- fetch_command_map(),
         [command | args] <- String.split(input, " ", trim: true) do
      case Map.get(command_map, command) do
        {module, function, _args} ->
          apply(module, function, [args])

        nil ->
          handle_unknown_command(input, command, args, command_map)
      end
    else
      {:error, :no_provider} -> {:error, "No simple_provider configured in config.exs"}
      [] -> {:ok, ""}
    end
  end

  @impl TioComodo.Repl.Provider.Behaviour
  def completions(buffer, _cursor_pos) do
    with {:ok, command_map} <- fetch_command_map() do
      command_map
      |> Map.keys()
      |> Enum.reject(&(&1 == "catchall_handler"))
      |> Enum.filter(&String.starts_with?(&1, buffer))
    else
      _ -> []
    end
  end

  defp handle_unknown_command(input, command, _args, command_map) do
    case Map.get(command_map, "catchall_handler") do
      {module, function, _args} ->
        apply(module, function, [input])

      nil ->
        {:error, "Unknown command: #{command}"}
    end
  end

  defp fetch_command_map do
    case Application.get_env(:tio_comodo, :simple_provider) do
      {module, function} -> {:ok, apply(module, function, [])}
      _ -> {:error, :no_provider}
    end
  end
end
