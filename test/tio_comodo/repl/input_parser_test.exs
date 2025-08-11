defmodule TioComodo.Repl.InputParserTest do
  use ExUnit.Case
  alias TioComodo.Repl.InputParser

  describe "parse/1" do
    test "handles single ASCII characters" do
      assert InputParser.parse("a") == [{:char, "a"}]
      assert InputParser.parse("1") == [{:char, "1"}]
      assert InputParser.parse("!") == [{:char, "!"}]
    end

    test "handles control characters" do
      assert InputParser.parse("\r") == [{:key, :enter}]
      assert InputParser.parse("\t") == [{:key, :tab}]
      # Backspace
      assert InputParser.parse("\x7F") == [{:key, :backspace}]
      # Delete
      assert InputParser.parse("\b") == [{:key, :backspace}]
      # Escape
      assert InputParser.parse("\e") == [{:key, :escape}]
    end

    test "handles arrow keys" do
      assert InputParser.parse("\e[A") == [{:key, :up}]
      assert InputParser.parse("\e[B") == [{:key, :down}]
      assert InputParser.parse("\e[C") == [{:key, :right}]
      assert InputParser.parse("\e[D") == [{:key, :left}]
    end

    test "handles other special keys" do
      assert InputParser.parse("\e[3~") == [{:key, :delete}]
      assert InputParser.parse("\e[H") == [{:key, :home}]
      assert InputParser.parse("\e[F") == [{:key, :end}]
    end

    test "handles multiple events in sequence" do
      assert InputParser.parse("abc") == [
               {:char, "a"},
               {:char, "b"},
               {:char, "c"}
             ]

      assert InputParser.parse("a\e[A") == [
               {:char, "a"},
               {:key, :up}
             ]
    end

    test "handles empty input" do
      assert InputParser.parse("") == []
    end

    test "handles UTF-8 characters" do
      # Test with a simple UTF-8 character
      assert InputParser.parse("ł") == [{:char, "ł"}]
      assert InputParser.parse("ñ") == [{:char, "ñ"}]
    end
  end
end
