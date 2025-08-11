defmodule TioComodo.Repl.InputParser do
  @moduledoc """
  Parses raw terminal input into structured events.

  This module handles:
  - Single-byte control characters (Enter, Tab, Backspace, etc.)
  - Multi-byte ANSI escape sequences (arrow keys, Delete key)
  - Multi-byte UTF-8 character sequences
  """

  # Control characters
  @escape 27
  @enter 13
  @tab 9
  @backspace 127
  @delete 8

  # ANSI escape sequences for special keys (defined as constants for reference)
  # @arrow_up "\e[A"
  # @arrow_down "\e[B"
  # @arrow_right "\e[C"
  # @arrow_left "\e[D"
  # @delete_key "\e[3~"
  # @home "\e[H"
  # @end_key "\e[F"

  @doc """
  Parses raw terminal input into a list of structured events.

  ## Examples

      iex> parse("\e[A")
      [{:key, :up}]

      iex> parse("a")
      [{:char, "a"}]

      iex> parse("\r")
      [{:key, :enter}]
  """
  @spec parse(binary()) :: list()
  def parse(input) when is_binary(input) do
    parse_bytes(input, [])
  end

  # Handle empty input
  defp parse_bytes(<<>>, events), do: Enum.reverse(events)

  # Handle ANSI escape sequences
  defp parse_bytes(<<@escape, ?[, ?A, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :up} | events])
  end

  defp parse_bytes(<<@escape, ?[, ?B, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :down} | events])
  end

  defp parse_bytes(<<@escape, ?[, ?C, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :right} | events])
  end

  defp parse_bytes(<<@escape, ?[, ?D, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :left} | events])
  end

  defp parse_bytes(<<@escape, ?[, ?3, ?~, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :delete} | events])
  end

  defp parse_bytes(<<@escape, ?[, ?H, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :home} | events])
  end

  defp parse_bytes(<<@escape, ?[, ?F, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :end} | events])
  end

  # Handle single-byte control characters
  defp parse_bytes(<<@enter, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :enter} | events])
  end

  defp parse_bytes(<<@tab, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :tab} | events])
  end

  defp parse_bytes(<<@backspace, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :backspace} | events])
  end

  defp parse_bytes(<<@delete, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :backspace} | events])
  end

  # Handle escape key (standalone)
  defp parse_bytes(<<@escape, rest::binary>>, events) do
    parse_bytes(rest, [{:key, :escape} | events])
  end

  # Handle UTF-8 characters (including ASCII)
  defp parse_bytes(<<byte::8, rest::binary>>, events) when byte < 128 do
    # ASCII character
    char = <<byte>>
    parse_bytes(rest, [{:char, char} | events])
  end

  defp parse_bytes(<<byte::8, rest::binary>>, events) when byte >= 128 do
    # Multi-byte UTF-8 character
    case parse_utf8_char(<<byte, rest::binary>>) do
      {:ok, char, remaining} ->
        parse_bytes(remaining, [{:char, char} | events])

      :error ->
        # Invalid UTF-8, skip this byte
        parse_bytes(rest, events)
    end
  end

  # Helper to parse multi-byte UTF-8 characters
  defp parse_utf8_char(input) do
    case :unicode.characters_to_list(input, :utf8) do
      {:incomplete, _chars, _} ->
        # Need more bytes
        :error

      {:error, _, _} ->
        # Invalid UTF-8
        :error

      chars when is_list(chars) ->
        # Valid UTF-8
        char = List.to_string(chars)
        char_length = String.length(char)
        remaining = String.slice(input, char_length..-1//1)
        {:ok, char, remaining}
    end
  end
end
