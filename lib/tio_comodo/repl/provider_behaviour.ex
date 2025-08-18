defmodule TioComodo.Repl.Provider.Behaviour do
  @moduledoc """
  A behaviour module for implementing a `TioComodo.Repl.Server` command provider.

  This behaviour allows you to customize the command handling and autocompletion
  logic of the REPL. To create a custom provider, you need to implement the
  callbacks defined in this module.

  ## Example Provider

      defmodule MyApp.Repl.Provider do
        @behaviour TioComodo.Repl.Provider.Behaviour

        @impl true
        def dispatch("hello") do
          {:ok, "world"}
        end

        def dispatch("exit") do
          {:stop, :normal, "Goodbye!"}
        end

        def dispatch(_command) do
          {:error, "Unknown command"}
        end

        @impl true
        def completions(buffer, _cursor_pos) do
          ["hello", "exit"]
          |> Enum.filter(&String.starts_with?(&1, buffer))
        end
      end

  You would then pass this provider to the `TioComodo.Repl.Server` when
  starting it:

      {TioComodo.Repl.Server, provider: MyApp.Repl.Provider}

  """

  @doc """
  Dispatches a command and returns the result.

  This function is called when the user presses Enter in the REPL. It receives
  the command string as input and should return a tuple indicating the result
  of the command.

  ## Return Values

  - `{:ok, message}` - The command was successful. `message` will be printed to
    the console.
  - `{:error, message}` - The command failed. `message` will be printed to the
    console, prefixed with "Error: ".
  - `{:stop, reason, message}` - The command was successful, and the REPL should
    terminate. `message` will be printed to the console, and the server will
    exit with the given `reason`.
  """
  @callback dispatch(command :: String.t()) ::
              {:ok, String.t()}
              | {:error, String.t()}
              | {:stop, any(), String.t()}

  @doc """
  Provides a list of completion suggestions.

  This function is called when the user presses Tab in the REPL. It receives
  the current input buffer and the cursor position as input and should return
  a list of strings representing the possible completions.
  """
  @callback completions(buffer :: String.t(), cursor_pos :: non_neg_integer()) :: [String.t()]
end
