# TioComodo

TioComodo provides a simple, embeddable Read-Eval-Print Loop (REPL) for your Elixir applications. It allows you to define a custom set of commands and run them in an interactive terminal session, for a simple terminal I/O application. TioComodo avoids native dependencies for ease of use. For a more advanced TUI, look at other packages like [Ratatouille](https://hex.pm/packages/ratatouille).

## Installation

To use TioComodo in your project, add it to your list of dependencies in `mix.exs`. You can point it to a local path or a Git repository.

```elixir
def deps do
  [
    # Example using a local path
    {:tio_comodo, path: "./path/to/tio_comodo"}
  ]
end
```

## Integration Guide

Follow these steps to integrate the TioComodo REPL into your Elixir application.

### 1. Create Commands Using the Simple Provider (Recommended)

The easiest way to add commands to your REPL is to use the built-in default provider `TioComodo.Repl.Provider` and supply a simple command map via `:simple_provider`.

Create a module that exposes `commands/0` returning a map of command names to `{module, function, []}`:

```elixir
# lib/my_app/repl/commands.ex

defmodule MyApp.Repl.Commands do
  @moduledoc "Commands for the REPL"

  def commands do
    %{
      "hello" => {__MODULE__, :hello, []},
      "time" => {__MODULE__, :time, []},
      "quit" => {__MODULE__, :quit, []}
    }
  end

  def hello(args), do: {:ok, "Hello, #{Enum.join(args, " ")}!"}
  def time(_args), do: {:ok, "Current time is: #{DateTime.utc_now() |> DateTime.to_string()}"}
  def quit(_args), do: {:stop, :normal, "Goodbye!"}
end
```

### 2. Configure the Simple Provider

Tell TioComodo to use your simple command map. In your `config/config.exs`, add the following:

```elixir
# config/config.exs

import Config

config :tio_comodo,
  simple_provider: {MyApp.Repl.Commands, :commands}
```

With this setup, you do not need to implement the full provider behaviour; the default provider will dispatch commands based on your `commands/0` map and also supply tab-completions from the command names.

### 3. Configure Colorscheme (Optional)

TioComodo includes a beautiful default colorscheme inspired by Gruvbox, but you can customize the colors to match your preferences. In your `config/config.exs`, add a colorscheme configuration:

```elixir
# config/config.exs

import Config

config :tio_comodo,
  simple_provider: {MyApp.Repl.Commands, :commands},
  colourscheme: [
    user: :green,        # Color for user input
    background: :black,  # Background color
    prompt: :blue,       # Prompt color
    error: :red,         # Error message color
    success: :green,     # Success message color
    warning: :yellow,    # Warning message color
    info: :blue,         # Info message color
    completion: :cyan    # Tab completion color
  ]
```

Available colors include standard terminal colors like `:red`, `:green`, `:blue`, `:yellow`, `:cyan`, `:magenta`, `:white`, and `:black`. You can also use lighter versions like `:light_red`, `:light_green`, etc. Note that colors must be specified as atoms (with colons), not as strings.

#### Optional: Add a Catchall Handler

You can optionally configure a catchall handler that will receive any input that doesn't match a defined command:

```elixir
# lib/my_app/repl/commands.ex

defmodule MyApp.Repl.Commands do
  @moduledoc "Commands for the REPL"

  def commands do
    %{
      "hello" => {__MODULE__, :hello, []},
      "time" => {__MODULE__, :time, []},
      "quit" => {__MODULE__, :quit, []}
    }
  end

  def hello(args), do: {:ok, "Hello, #{Enum.join(args, " ")}!"}
  def time(_args), do: {:ok, "Current time is: #{DateTime.utc_now() |> DateTime.to_string()}"}
  def quit(_args), do: {:stop, :normal, "Goodbye!"}

  # Catchall handler receives the full input string
  def handle_unknown(input) do
    {:ok, "I don't understand: #{input}. Try 'hello', 'time', or 'quit'."}
  end
end
```

Configure both the simple provider and the catchall handler:

```elixir
# config/config.exs

import Config

config :tio_comodo,
  simple_provider: {MyApp.Repl.Commands, :commands},
  catchall_handler: {MyApp.Repl.Commands, :handle_unknown}
```

The catchall handler will not appear in tab-completion suggestions.

### 4. Alternative: Create a Custom Command Provider

If you need more control over command parsing and dispatch, you can implement a full command provider module.

Create a new file, for example, at `lib/my_app/repl/custom_commands.ex`:

```elixir
# lib/my_app/repl/custom_commands.ex

defmodule MyApp.Repl.CustomCommands do
  @moduledoc "Provides commands for the interactive REPL."

  @doc "Handles command dispatch."
  def dispatch(command_line) do
    # Simple parsing: command is the first word, args are the rest.
    [command | args] = String.split(command_line)

    case command do
      "hello" -> hello(args)
      "time" -> time(args)
      "quit" -> quit(args)
      _ -> {:error, "Unknown command: #{command}"}
    end
  end

  # Command Implementations

  defp hello([]), do: {:ok, "Hello, World!"}
  defp hello(args), do: {:ok, "Hello, #{Enum.join(args, " ")}!"}

  defp time(_args) do
    {:ok, "Current time is: #{DateTime.utc_now() |> DateTime.to_string()}"}
  end

  defp quit(_args) do
    # This special tuple signals the REPL server to stop.
    {:stop, :normal, "Goodbye!"}
  end
end
```

Then configure TioComodo to use your custom command provider:

```elixir
# config/config.exs

import Config

config :tio_comodo,
  provider: MyApp.Repl.CustomCommands
```

### 5. Update Your Application Supervisor

To run the REPL when your application starts, you need to add the `TioComodo.Repl.Server` to your application's supervision tree. You also need a lightweight process to listen for the REPL's termination signal to ensure a clean shutdown of the entire application.

Modify your `lib/my_app/application.ex` file:

```elixir
# lib/my_app/application.ex

defmodule MyApp.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    # This process waits for the REPL to terminate, then stops the entire VM.
    parent = spawn_link(fn ->
      receive do
        :repl_terminated -> :init.stop()
      end
    end)

    children = [
      # Start the TioComodo REPL server, passing it the parent PID.
      # The server will send :repl_terminated to the parent when it exits.
      {TioComodo.Repl.Server, prompt: "my_app> ", name: MyApp.Repl, parent: parent}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

**Explanation:**
- We `spawn_link` a new, lightweight process whose only job is to wait for a `:repl_terminated` message.
- When the user issues the `quit` command, the REPL server sends this message to the spawned process (its `parent`).
- Upon receiving the message, the process calls `:init.stop()`, which gracefully terminates the entire Erlang VM, ensuring your application exits cleanly.
- The `TioComodo.Repl.Server` is started as a child in the supervision tree, configured with a custom prompt and the parent's PID.

### 6. Run Your Application

Now you are ready to run your application's REPL. Use the following command, and the interactive prompt will appear.

```bash
$ mix run --no-halt
my_app> 
```

You can now use the `hello`, `time`, and `quit` commands.
