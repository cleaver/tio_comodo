defmodule TioComodo.Repl.Render do
  @moduledoc """
  Handles rendering of the REPL interface using ANSI escape codes and colors.

  This module is responsible for:
  - Redrawing the current line with prompt and buffer
  - Positioning the cursor correctly
  - Displaying autocomplete suggestions
  - All terminal output operations
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
    home_cursor()

    # Clear the entire line
    clear_line()

    # Print colored prompt and buffer
    colored_prompt = Colorscheme.colorize(prompt, :prompt)
    IO.write(colored_prompt <> buffer)

    # Position cursor at the correct position
    # We need to move back from the end of the buffer to the cursor position
    # Use Ucwidth.width for proper emoji and CJK character handling
    buffer_length = Ucwidth.width(buffer)
    chars_to_move_back = buffer_length - cursor_pos

    if chars_to_move_back > 0 do
      # Move cursor back by the required number of characters
      move_cursor_back(chars_to_move_back)
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
    newline()

    # Print each completion with a colored bullet point
    Enum.each(completions, fn completion ->
      colored_bullet = Colorscheme.colorize("  • ", :completion)
      IO.write(colored_bullet <> completion)
      newline()
    end)

    # Move back up to the original line
    lines_to_move_up = length(completions) + 1
    move_cursor_up(lines_to_move_up)
  end

  @doc """
  Prints error messages with error color styling.
  """
  @spec print_error(String.t()) :: :ok
  def print_error(message) do
    colored_message = Colorscheme.colorize(message, :error)
    IO.write(colored_message)
  end

  # Terminal output control functions

  @doc "Prints a newline with carriage return"
  @spec newline() :: :ok
  def newline, do: IO.write("\r\n")

  @doc "Moves cursor to beginning of line"
  @spec home_cursor() :: :ok
  def home_cursor, do: IO.write("\r")

  @doc "Clears the entire line"
  @spec clear_line() :: :ok
  def clear_line, do: IO.write("\e[K")

  @doc "Moves cursor up by specified number of lines"
  @spec move_cursor_up(non_neg_integer()) :: :ok
  def move_cursor_up(lines), do: IO.write("\e[#{lines}A")

  @doc "Moves cursor back by specified number of characters"
  @spec move_cursor_back(non_neg_integer()) :: :ok
  def move_cursor_back(chars), do: IO.write("\e[#{chars}D")

  @doc "Prints text with newline replacement for proper terminal formatting"
  @spec print_with_newlines(String.t()) :: :ok
  def print_with_newlines(text) do
    formatted_text = String.replace(text, ~r/(?<!\r)\n/u, "\r\n")
    IO.write(formatted_text)
  end

  @doc "Prints a command with user color styling and newlines"
  @spec print_command(String.t()) :: :ok
  def print_command(command) do
    newline()
    colored_command = Colorscheme.colorize(command, :user)
    IO.write(colored_command)
    newline()
  end

  @doc "Prints an empty line"
  @spec print_empty_line() :: :ok
  def print_empty_line, do: newline()

  @doc "Prints success messages with success color styling and newlines"
  @spec print_success(String.t()) :: :ok
  def print_success(message) do
    colored_message = Colorscheme.colorize(message, :success)
    print_with_newlines(colored_message)
    newline()
  end

  @doc "Prints info messages with info color styling and newlines"
  @spec print_info(String.t()) :: :ok
  def print_info(message) do
    colored_message = Colorscheme.colorize(message, :info)
    print_with_newlines(colored_message)
    newline()
  end
end
