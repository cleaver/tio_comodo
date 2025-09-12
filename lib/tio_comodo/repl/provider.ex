defmodule TioComodo.Repl.Provider do
  @moduledoc """
  A provider that fetches commands from a user-defined function.

  This is the default provider used by TioComodo when configured with a simple
  command map via the `:simple_provider` configuration option.

  ## Configuration

  Configure this provider in your `config/config.exs`:

      config :tio_comodo,
        simple_provider: {MyApp.Repl.Commands, :commands}

  ## Example Command Module

  Create a module that exposes a `commands/0` function returning a map of command
  names to `{module, function, []}` tuples:

      defmodule MyApp.Repl.Commands do
        @moduledoc "Commands for the REPL"

        def commands do
          %{
            "hello" => {__MODULE__, :hello, []},
            "time" => {__MODULE__, :time, []},
            "long_task" => {__MODULE__, :long_task, []},
            "quit" => {__MODULE__, :quit, []}
          }
        end

        def hello(args), do: {:ok, "Hello, " <> Enum.join(args, " ") <> "!"}

        def time(_args), do: {:ok, "Current time is: " <> DateTime.utc_now() |> DateTime.to_string()}

        def long_task(_args) do
          # Start a background process that sends output to the REPL
          spawn(fn ->
            TioComodo.Repl.Server.output("Starting long task...")
            Process.sleep(2000)
            TioComodo.Repl.Server.output("Task 50% complete...")
            Process.sleep(2000)
            TioComodo.Repl.Server.output("Task completed successfully!")
          end)

          {:ok, "Long task started in background"}
        end

        def quit(_args), do: {:stop, :normal, "Goodbye!"}
      end

  ## Command Return Values

  Commands should return one of the following tuples:

  - `{:ok, message}` - Display a success message
  - `{:ok, ""}` - Display nothing (useful for silent commands)
  - `{:error, message}` - Display an error message
  - `{:stop, reason, message}` - Stop the REPL with the given reason

  ## Catchall Handler

  You can optionally add a catchall handler to handle unknown commands:

      def commands do
        %{
          "hello" => {__MODULE__, :hello, []},
          "quit" => {__MODULE__, :quit, []},
          "catchall_handler" => {__MODULE__, :handle_unknown, []}
        }
      end

      def handle_unknown(input) do
        {:ok, "I don't understand: " <> input <> ". Try 'hello' or 'quit'."}
      end

  The catchall handler will not appear in tab-completion suggestions.
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
