defmodule TioComodo.Repl.Helpers.HistoryTest do
  use ExUnit.Case, async: true

  alias TioComodo.Repl.Helpers.History

  setup do
    # Create a unique temporary directory for each test
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "tio_comodo_history_test_" <> Integer.to_string(:erlang.unique_integer([:positive]))
      )

    File.mkdir_p!(tmp_dir)

    # Set the environment variable to our temporary directory
    original_xdg_state_home = System.get_env("XDG_STATE_HOME")
    System.put_env("XDG_STATE_HOME", tmp_dir)

    # Clean up the temporary directory and restore env var on exit
    on_exit(fn ->
      if is_nil(original_xdg_state_home) do
        System.delete_env("XDG_STATE_HOME")
      else
        System.put_env("XDG_STATE_HOME", original_xdg_state_home)
      end

      File.rm_rf!(tmp_dir)
    end)

    :ok
  end

  describe "history_basename/0" do
    test "returns configured basename when set" do
      Application.put_env(:temp_cli, :repl_history_basename, "custom_history")
      assert History.history_basename() == "custom_history"
      Application.delete_env(:temp_cli, :repl_history_basename)
    end

    test "falls back to a default basename ending in _history" do
      Application.delete_env(:temp_cli, :repl_history_basename)
      assert History.history_basename() |> String.ends_with?("_history")
    end
  end

  describe "history_file_path/0" do
    test "creates the directory and returns the correct file path" do
      path = History.history_file_path()
      # Check that the parent directory was created
      assert File.dir?(Path.dirname(path))
      # Check that the filename is correct
      assert Path.basename(path) == History.history_basename()
    end
  end

  describe "load_history/0 and persist_history_item/1" do
    test "load_history returns an empty list when the file is missing" do
      assert History.load_history() == []
    end

    test "persisted items can be loaded" do
      History.persist_history_item("first")
      History.persist_history_item("second")
      assert History.load_history() == ["first", "second"]
    end

    test "persisting an empty item is a no-op" do
      History.persist_history_item("first")
      History.persist_history_item("")
      History.persist_history_item("second")
      assert History.load_history() == ["first", "second"]
    end
  end
end