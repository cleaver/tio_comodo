defmodule TioComodo.Repl.Server do
  @moduledoc """
  The core REPL server that manages state and coordinates input/output.

  This GenServer is responsible for:
  - Managing the REPL state (buffer, cursor position, history, etc.)
  - Coordinating between input parsing and rendering
  - Handling terminal mode switching
  - Processing user input events
  """

  use GenServer
  require Logger

  alias TioComodo.Repl.{InputParser, Render}
  alias TioComodo.Repl.Helpers.{History, Autocomplete}
  alias TioComodo.Repl.Provider

  @doc """
  Represents the state of the REPL server.
  """
  defstruct [
    # Current input buffer
    :buffer,
    # Current cursor position within buffer
    :cursor_pos,
    # List of previous commands
    :history,
    # Current position in history navigation
    :history_pos,
    # Buffer that was present before starting history navigation
    :original_buffer,
    # Prompt string to display
    :prompt,
    # PID of the reader process
    :reader_pid,
    # Module implementing `TioComodo.Repl.Provider`
    :provider
  ]

  @type t :: %__MODULE__{
          buffer: String.t(),
          cursor_pos: non_neg_integer(),
          history: [String.t()],
          history_pos: non_neg_integer(),
          original_buffer: String.t() | nil,
          prompt: String.t(),
          reader_pid: pid() | nil,
          provider: module()
        }

  @doc """
  Starts the REPL server.

  ## Options

  - `:prompt` - The prompt string to display (default: "> ")
  - `:name` - The registered name for the server (optional)
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Gets the current REPL state.
  """
  @spec get_state(GenServer.server()) :: t()
  def get_state(server \\ __MODULE__) do
    GenServer.call(server, :get_state)
  end

  # GenServer callbacks

  @impl GenServer
  def init(opts) do
    # Switch terminal to raw mode
    switch_to_raw_mode()

    # Spawn and link the reader process
    reader_pid = spawn_link(&read_loop/0)

    # Initialize state
    provider =
      Keyword.get(opts, :provider) ||
        Application.get_env(:tio_comodo, :provider, Provider)

    state = %__MODULE__{
      buffer: "",
      cursor_pos: 0,
      history: History.load_history(),
      history_pos: 0,
      original_buffer: nil,
      prompt: Keyword.get(opts, :prompt, "> "),
      reader_pid: reader_pid,
      provider: provider
    }

    # Perform initial render
    Render.redraw(state)

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_state, _from, %__MODULE__{} = state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_cast({:keypress, events}, %__MODULE__{} = state) do
    # Process each event
    new_state = Enum.reduce(events, state, &handle_event/2)

    # Redraw the interface
    Render.redraw(new_state)

    {:noreply, new_state}
  end

  @impl GenServer
  def terminate(_reason, _state) do
    # Restore terminal to cooked mode
    :shell.start_interactive(:noshell)
  end

  @impl GenServer
  def handle_info({:stop, reason}, state) do
    {:stop, reason, state}
  end

  # Private functions

  defp switch_to_raw_mode do
    :shell.start_interactive({:noshell, :raw})
  end

  defp read_loop do
    # Block on reading input
    case :io.get_chars("", 1024) do
      :eof ->
        # End of input, exit the loop
        :ok

      {:error, reason} ->
        Logger.error("Error reading input: #{inspect(reason)}")
        read_loop()

      input when is_binary(input) ->
        # Parse the input and send events to the server
        events = InputParser.parse(input)
        GenServer.cast(__MODULE__, {:keypress, events})
        read_loop()
    end
  end

  # Event handlers

  defp handle_event({:char, char}, %__MODULE__{} = state) do
    # Insert character at cursor position
    before_cursor = String.slice(state.buffer, 0, state.cursor_pos)
    after_cursor = String.slice(state.buffer, state.cursor_pos..-1//1)
    new_buffer = before_cursor <> char <> after_cursor

    %{state | buffer: new_buffer, cursor_pos: state.cursor_pos + String.length(char)}
  end

  defp handle_event({:key, :backspace}, %__MODULE__{} = state) do
    if state.cursor_pos > 0 do
      # Remove character to the left of cursor
      before_cursor = String.slice(state.buffer, 0, state.cursor_pos - 1)
      after_cursor = String.slice(state.buffer, state.cursor_pos..-1//1)
      new_buffer = before_cursor <> after_cursor

      %{state | buffer: new_buffer, cursor_pos: state.cursor_pos - 1}
    else
      state
    end
  end

  defp handle_event({:key, :left}, %__MODULE__{} = state) do
    if state.cursor_pos > 0 do
      %{state | cursor_pos: state.cursor_pos - 1}
    else
      state
    end
  end

  defp handle_event({:key, :right}, %__MODULE__{} = state) do
    if state.cursor_pos < String.length(state.buffer) do
      %{state | cursor_pos: state.cursor_pos + 1}
    else
      state
    end
  end

  defp handle_event({:key, :up}, %__MODULE__{} = state) do
    if state.history_pos < length(state.history) do
      # Capture the original buffer only when starting history navigation
      original_buffer = if state.history_pos == 0, do: state.buffer, else: state.original_buffer

      new_history_pos = state.history_pos + 1
      history_item = Enum.at(state.history, length(state.history) - new_history_pos)

      %{
        state
        | buffer: history_item,
          cursor_pos: String.length(history_item),
          history_pos: new_history_pos,
          original_buffer: original_buffer
      }
    else
      state
    end
  end

  defp handle_event({:key, :down}, %__MODULE__{} = state) do
    if state.history_pos > 0 do
      new_history_pos = state.history_pos - 1

      if new_history_pos == 0 do
        # Return to the original buffer (empty if we started with empty buffer)
        restored = state.original_buffer || ""

        %{
          state
          | buffer: restored,
            cursor_pos: String.length(restored),
            history_pos: 0,
            original_buffer: nil
        }
      else
        history_item = Enum.at(state.history, length(state.history) - new_history_pos)

        %{
          state
          | buffer: history_item,
            cursor_pos: String.length(history_item),
            history_pos: new_history_pos
        }
      end
    else
      state
    end
  end

  defp handle_event({:key, :enter}, %__MODULE__{} = state) do
    process_command(state)
  end

  defp handle_event({:key, :tab}, %__MODULE__{} = state) do
    # Get completions from the configured provider
    completions = state.provider.completions(state.buffer, state.cursor_pos)

    case completions do
      [] ->
        # No completions available, do nothing
        state

      [single_completion] ->
        # Single completion, replace the current word with the completion
        new_buffer =
          Autocomplete.replace_word_at_cursor(state.buffer, state.cursor_pos, single_completion)

        new_cursor_pos =
          state.cursor_pos +
            (String.length(single_completion) -
               Autocomplete.get_word_length_at_cursor(state.buffer, state.cursor_pos))

        %{state | buffer: new_buffer, cursor_pos: new_cursor_pos}

      multiple_completions ->
        # Multiple completions, display them
        Render.print_completions(multiple_completions)
        state
    end
  end

  defp handle_event({:key, :escape}, %__MODULE__{} = state) do
    # TODO: Implement escape key handling
    # For now, just ignore escape
    state
  end

  defp handle_event({:key, :delete}, %__MODULE__{} = state) do
    # Same as backspace for now
    handle_event({:key, :backspace}, state)
  end

  defp handle_event({:key, :home}, %__MODULE__{} = state) do
    %{state | cursor_pos: 0}
  end

  defp handle_event({:key, :end}, %__MODULE__{} = state) do
    %{state | cursor_pos: String.length(state.buffer)}
  end

  defp handle_event(_event, %__MODULE__{} = state) do
    # Ignore unknown events
    state
  end

  defp process_command(%__MODULE__{} = state) do
    trimmed = String.trim(state.buffer)

    if trimmed != "" do
      # Add command to history
      new_history = state.history ++ [trimmed]
      History.persist_history_item(trimmed)

      # Print the command on a new line
      IO.write("\r\n")

      # Dispatch the command
      state.provider.dispatch(trimmed)
      |> handle_dispatch_result()

      # Clear buffer and reset cursor
      new_state = %{
        state
        | buffer: "",
          cursor_pos: 0,
          history: new_history,
          history_pos: 0,
          original_buffer: nil
      }

      # Redraw the prompt after output
      Render.redraw(new_state)

      new_state
    else
      # Just print a new line for empty input
      IO.write("\r\n")
      state
    end
  end

  defp handle_dispatch_result({:ok, message}) when message != "" do
    IO.write(String.replace(message, ~r/(?<!\r)\n/u, "\r\n"))
    IO.write("\r\n")
  end

  defp handle_dispatch_result({:ok, ""}) do
    :ok
  end

  defp handle_dispatch_result({:error, message}) do
    IO.write("Error: #{message}\r\n")
  end

  defp handle_dispatch_result({:stop, reason, message}) do
    IO.write(String.replace(message, ~r/(?<!\r)\n/u, "\r\n"))
    IO.write("\r\n")
    # Signal to stop the REPL
    Process.send_after(self(), {:stop, reason}, 0)
  end

  # Helper functions for autocompletion moved to TioComodo.Repl.Helpers.Autocomplete

  # History naming helpers moved to TioComodo.Repl.Helpers.History
end
