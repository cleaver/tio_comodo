defmodule TioComodo.Repl.Render do
  @moduledoc """
  Handles rendering of the REPL interface using ANSI escape codes.

  This module is responsible for:
  - Redrawing the current line with prompt and buffer
  - Positioning the cursor correctly
  - Displaying autocomplete suggestions
  """

  @doc """
  Redraws the current line with the prompt, buffer, and cursor positioned correctly.

  Takes a state struct containing:
  - :prompt - The prompt string to display
  - :buffer - The current input buffer
  - :cursor_pos - The current cursor position within the buffer

  Uses ANSI escape codes to:
  1. Move cursor to beginning of line (\r)
  2. Clear the entire line (\e[K)
  3. Print the prompt and buffer
  4. Position the cursor at the correct position
  """
  @spec redraw(map()) :: :ok
  def redraw(%{prompt: prompt, buffer: buffer, cursor_pos: cursor_pos}) do
    # Move cursor to beginning of line
    IO.write("\r")

    # Clear the entire line
    IO.write("\e[K")

    # Print prompt and buffer
    IO.write(prompt <> buffer)

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
  Displays them in a formatted list below the current prompt.
  """
  @spec print_completions([String.t()]) :: :ok
  def print_completions([]), do: :ok

  def print_completions(completions) when is_list(completions) do
    # Move to next line, ensuring carriage return
    IO.write("\r\n")

    # Print each completion with a bullet point
    Enum.each(completions, fn completion ->
      IO.write("  • #{completion}\r\n")
    end)

    # Move back up to the original line
    lines_to_move_up = length(completions) + 1
    IO.write("\e[#{lines_to_move_up}A")
  end
end
