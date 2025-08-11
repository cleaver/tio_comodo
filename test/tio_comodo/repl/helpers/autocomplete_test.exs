defmodule TioComodo.Repl.Helpers.AutocompleteTest do
  use ExUnit.Case, async: true

  alias TioComodo.Repl.Helpers.Autocomplete

  describe "replace_word_at_cursor/3" do
    test "replaces word in the middle of buffer" do
      assert Autocomplete.replace_word_at_cursor("git sta", 6, "status") == "git status"
    end

    test "replaces at start of buffer" do
      assert Autocomplete.replace_word_at_cursor("ls -la", 0, "echo") == "echo -la"
    end

    test "replaces at end of buffer" do
      assert Autocomplete.replace_word_at_cursor("mix te", 6, "test") == "mix test"
    end
  end

  describe "get_word_length_at_cursor/2" do
    test "length of current word at cursor" do
      assert Autocomplete.get_word_length_at_cursor("git sta", 6) == 3
      assert Autocomplete.get_word_length_at_cursor("abc", 1) == 3
    end
  end

  describe "find_word_start/2 and find_word_end/2" do
    test "handles spaces and boundaries" do
      buffer = "cmd sub arg"
      assert Autocomplete.find_word_start(buffer, 7) == 4
      # When cursor is on a space, end should be the index of that space
      assert Autocomplete.find_word_end(buffer, 7) == 7
    end
  end
end
