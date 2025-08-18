defmodule TioComodo.Repl.Render do
  @moduledoc """
  Handles rendering of the REPL interface using ANSI escape codes and colors.

  This module is responsible for:
  - Redrawing the current line with prompt and buffer
  - Positioning the cursor correctly
  - Displaying autocomplete suggestions
  - Rendering colored output for various message types
  """

  alias TioComodo.Colorscheme

  @doc """
  Redraws the current line with the prompt, buffer, and cursor positioned correctly.

  Takes a state struct containing:
  - :prompt - The prompt string to display
  - :buffer - The current input buffer
  - :cursor_pos - The current cursor position within the buffer

  Uses ANSI escape codes to:
  1. Move cursor to beginning of line (\r)
  2. Clear the entire line (\e[K)
  3. Print the colored prompt and buffer
  4. Position the cursor at the correct position
  """
  @spec redraw(map()) :: :ok
  def redraw(%{prompt: prompt, buffer: buffer, cursor_pos: cursor_pos}) do
    # Move cursor to beginning of line
    IO.write("\r")

    # Clear the entire line
    IO.write("\e[K")

    # Print colored prompt and buffer
    colored_prompt = Colorscheme.colorize(prompt, :prompt)
    IO.write(colored_prompt <> buffer)

    # Position cursor at the correct position
    # We need to move back from the end of the buffer to the cursor position
    buffer_length = String.length(buffer)
    chars_to_move_back = buffer_length - cursor_pos

    if chars_to_move_back > 0 do
      # Move cursor back by the required number of characters
      IO.write("\e[#{chars_to_move_back}D")
    end
  end

  @doc """
  Prints a list of completion suggestions below the current line.

  Takes a list of strings representing the available completions.
  Displays them in a formatted list below the current prompt with colored bullet points.
  """
  @spec print_completions([String.t()]) :: :ok
  def print_completions([]), do: :ok

  def print_completions(completions) when is_list(completions) do
    # Move to next line, ensuring carriage return
    IO.write("\r\n")

    # Print each completion with a colored bullet point
    Enum.each(completions, fn completion ->
      colored_bullet = Colorscheme.colorize("  • ", :completion)
      IO.write(colored_bullet <> completion <> "\r\n")
    end)

    # Move back up to the original line
    lines_to_move_up = length(completions) + 1
    IO.write("\e[#{lines_to_move_up}A")
  end

  @doc """
  Prints error messages with error color styling.
  """
  @spec print_error(String.t()) :: :ok
  def print_error(message) do
    colored_message = Colorscheme.colorize(message, :error)
    IO.write(colored_message)
  end

  @doc """
  Prints success messages with success color styling.
  """
  @spec print_success(String.t()) :: :ok
  def print_success(message) do
    colored_message = Colorscheme.colorize(message, :success)
    IO.write(colored_message)
  end

  @doc """
  Prints warning messages with warning color styling.
  """
  @spec print_warning(String.t()) :: :ok
  def print_warning(message) do
    colored_message = Colorscheme.colorize(message, :warning)
    IO.write(colored_message)
  end

  @doc """
  Prints info messages with info color styling.
  """
  @spec print_info(String.t()) :: :ok
  def print_info(message) do
    colored_message = Colorscheme.colorize(message, :info)
    IO.write(colored_message)
  end
end
