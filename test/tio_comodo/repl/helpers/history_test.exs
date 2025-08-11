defmodule TioComodo.Repl.Helpers.HistoryTest do
  use ExUnit.Case, async: true

  alias TioComodo.Repl.Helpers.History

  defp with_tmp_state_dir(fun) when is_function(fun, 1) do
    tmp_dir =
      Path.join(
        System.tmp_dir!(),
        "temp_cli_test_" <> Integer.to_string(:erlang.unique_integer([:positive]))
      )

    File.rm_rf(tmp_dir)
    File.mkdir_p!(tmp_dir)

    original = System.get_env("XDG_STATE_HOME")

    try do
      System.put_env("XDG_STATE_HOME", tmp_dir)
      fun.(tmp_dir)
    after
      if is_nil(original) do
        System.delete_env("XDG_STATE_HOME")
      else
        System.put_env("XDG_STATE_HOME", original)
      end

      File.rm_rf(tmp_dir)
    end
  end

  describe "history_basename/0" do
    setup do
      original = Application.get_env(:temp_cli, :repl_history_basename)

      on_exit(fn ->
        if is_nil(original) do
          Application.delete_env(:temp_cli, :repl_history_basename)
        else
          Application.put_env(:temp_cli, :repl_history_basename, original)
        end
      end)

      :ok
    end

    test "returns configured basename when set" do
      Application.put_env(:temp_cli, :repl_history_basename, "custom_history")
      assert History.history_basename() == "custom_history"
    end

    test "falls back to default basename when not configured" do
      Application.delete_env(:temp_cli, :repl_history_basename)

      expected =
        case :application.get_application(self()) do
          {:ok, app} ->
            Atom.to_string(app) <> "_history"

          :undefined ->
            case Application.get_application(History) do
              nil -> "history"
              app -> Atom.to_string(app) <> "_history"
            end
        end

      assert History.history_basename() == expected
    end
  end

  describe "default_history_basename/0" do
    test "returns a basename derived from the current or module's application" do
      expected =
        case :application.get_application(self()) do
          {:ok, app} ->
            Atom.to_string(app) <> "_history"

          :undefined ->
            case Application.get_application(History) do
              nil -> "history"
              app -> Atom.to_string(app) <> "_history"
            end
        end

      assert History.default_history_basename() == expected
    end
  end

  describe "history file operations" do
    test "history_file_path creates directory and returns file path" do
      with_tmp_state_dir(fn base ->
        path = History.history_file_path()
        assert String.starts_with?(path, Path.join(base, "tio_comodo"))
        assert String.ends_with?(path, History.history_basename())
        assert File.dir?(Path.join(base, "tio_comodo"))
      end)
    end

    test "load_history returns [] when file missing and then reads persisted items" do
      with_tmp_state_dir(fn _ ->
        assert History.load_history() == []

        History.persist_history_item("")
        assert History.load_history() == []

        History.persist_history_item("first")
        History.persist_history_item("second")

        assert History.load_history() == ["first", "second"]
      end)
    end
  end
end
