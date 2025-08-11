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
          {:error, "Unknown command: #{command}"}
      end
    else
      {:error, :no_provider} -> {:error, "No command_provider configured in config.exs"}
      [] -> {:ok, ""}
    end
  end

  @impl TioComodo.Repl.Provider.Behaviour
  def completions(buffer, _cursor_pos) do
    with {:ok, command_map} <- fetch_command_map() do
      command_map
      |> Map.keys()
      |> Enum.filter(&String.starts_with?(&1, buffer))
    else
      _ -> []
    end
  end

  defp fetch_command_map do
    case Application.get_env(:tio_comodo, :command_provider) do
      {module, function} -> {:ok, apply(module, function, [])}
      _ -> {:error, :no_provider}
    end
  end
end
