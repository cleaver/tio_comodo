defmodule TioComodo.Repl.Helpers.Autocomplete do
  @moduledoc """
  Helpers for command-line autocompletion string manipulation.
  """

  @doc """
  Replaces the word at the given cursor position with the provided replacement.
  """
  @spec replace_word_at_cursor(String.t(), non_neg_integer(), String.t()) :: String.t()
  def replace_word_at_cursor(buffer, cursor_pos, replacement) do
    word_start = find_word_start(buffer, cursor_pos)
    word_end = find_word_end(buffer, cursor_pos)

    before_word = String.slice(buffer, 0, word_start)
    after_word = String.slice(buffer, word_end..-1//1)

    before_word <> replacement <> after_word
  end

  @doc """
  Returns the length of the word that the cursor is currently on.
  """
  @spec get_word_length_at_cursor(String.t(), non_neg_integer()) :: non_neg_integer()
  def get_word_length_at_cursor(buffer, cursor_pos) do
    word_start = find_word_start(buffer, cursor_pos)
    word_end = find_word_end(buffer, cursor_pos)

    word_end - word_start
  end

  @doc false
  @spec find_word_start(String.t(), non_neg_integer()) :: non_neg_integer()
  def find_word_start(buffer, cursor_pos) do
    buffer
    |> String.slice(0, cursor_pos)
    |> find_last_space()
    |> case do
      nil -> 0
      pos -> pos + 1
    end
  end

  @doc false
  @spec find_word_end(String.t(), non_neg_integer()) :: non_neg_integer()
  def find_word_end(buffer, cursor_pos) do
    buffer
    |> String.slice(cursor_pos..-1//1)
    |> find_first_space()
    |> case do
      nil -> String.length(buffer)
      pos -> cursor_pos + pos
    end
  end

  @doc false
  @spec find_last_space(String.t()) :: nil | non_neg_integer()
  def find_last_space(str) do
    str
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.filter(fn {char, _} -> char == " " end)
    |> List.last()
    |> case do
      nil -> nil
      {_, index} -> index
    end
  end

  @doc false
  @spec find_first_space(String.t()) :: nil | non_neg_integer()
  def find_first_space(str) do
    str
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.find(fn {char, _} -> char == " " end)
    |> case do
      nil -> nil
      {_, index} -> index
    end
  end
end
