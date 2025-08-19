defmodule TioComodo.Repl.ServerTest do
  use ExUnit.Case, async: false

  alias TioComodo.Repl.Server
  alias TioComodo.Repl.Helpers.History

  # Mock provider for testing
  defmodule MockProvider do
    def dispatch("hello"), do: {:ok, "Hello, World!"}
    def dispatch("error"), do: {:error, "Something went wrong"}
    def dispatch("quit"), do: {:stop, :normal, "Goodbye!"}
    def dispatch(_), do: {:ok, ""}

    def completions(buffer, _) do
      case buffer do
        "h" -> ["hello", "help"]
        "he" -> ["hello"]
        _ -> []
      end
    end
  end

  # Helper to start a uniquely named and configured server for a test
  defp start_server do
    server_name = :"test_repl_#{System.unique_integer([:positive])}"
    history_basename = "test_history_#{System.unique_integer([:positive])}"

    # Configure a unique history file for this test
    Application.put_env(:temp_cli, :repl_history_basename, history_basename)

    {:ok, server_pid} = Server.start_link(
      prompt: "test> ",
      provider: MockProvider,
      name: server_name
    )

    # Give the server a moment to initialize
    Process.sleep(10)

    on_exit(fn ->
      # Clean up the history file
      File.rm(History.history_file_path())
      Application.delete_env(:temp_cli, :repl_history_basename)

      try do
        GenServer.stop(server_pid, :normal)
      catch
        :exit, _ -> :ok
      end
    end)

    server_pid
  end

  describe "server initialization" do
    test "starts with correct initial state" do
      server_pid = start_server()
      state = Server.get_state(server_pid)

      assert state.prompt == "test> "
      assert state.provider == MockProvider
      assert state.buffer == ""
      assert state.cursor_pos == 0
      assert is_pid(state.reader_pid)
    end
  end

  describe "handle_event/2" do
    test "handles character input" do
      server_pid = start_server()
      GenServer.cast(server_pid, {:keypress, [{:char, "a"}]})
      state = Server.get_state(server_pid)
      assert state.buffer == "a"
      assert state.cursor_pos == 1

      GenServer.cast(server_pid, {:keypress, [{:char, "b"}]})
      state = Server.get_state(server_pid)
      assert state.buffer == "ab"
      assert state.cursor_pos == 2
    end

    test "handles backspace" do
      server_pid = start_server()
      GenServer.cast(server_pid, {:keypress, [{:char, "a"}, {:char, "b"}]})
      GenServer.cast(server_pid, {:keypress, [{:key, :backspace}]})
      state = Server.get_state(server_pid)
      assert state.buffer == "a"
      assert state.cursor_pos == 1

      GenServer.cast(server_pid, {:keypress, [{:key, :backspace}]})
      state = Server.get_state(server_pid)
      assert state.buffer == ""
      assert state.cursor_pos == 0

      # Test backspace on empty buffer
      GenServer.cast(server_pid, {:keypress, [{:key, :backspace}]})
      state = Server.get_state(server_pid)
      assert state.buffer == ""
      assert state.cursor_pos == 0
    end

    test "handles left and right arrow keys" do
      server_pid = start_server()
      GenServer.cast(server_pid, {:keypress, [{:char, "a"}, {:char, "b"}]})
      GenServer.cast(server_pid, {:keypress, [{:key, :left}]})
      state = Server.get_state(server_pid)
      assert state.cursor_pos == 1

      GenServer.cast(server_pid, {:keypress, [{:key, :right}]})
      state = Server.get_state(server_pid)
      assert state.cursor_pos == 2
    end

    test "handles home and end keys" do
      server_pid = start_server()
      GenServer.cast(server_pid, {:keypress, [{:char, "a"}, {:char, "b"}]})
      GenServer.cast(server_pid, {:keypress, [{:key, :home}]})
      state = Server.get_state(server_pid)
      assert state.cursor_pos == 0

      GenServer.cast(server_pid, {:keypress, [{:key, :end}]})
      state = Server.get_state(server_pid)
      assert state.cursor_pos == 2
    end

    test "handles up and down arrow for history" do
      server_pid = start_server()
      # Add some history
      GenServer.cast(server_pid, {:keypress, [{:char, "cmd1"}, {:key, :enter}]})
      GenServer.cast(server_pid, {:keypress, [{:char, "cmd2"}, {:key, :enter}]})

      # Navigate up
      GenServer.cast(server_pid, {:keypress, [{:key, :up}]})
      state = Server.get_state(server_pid)
      assert state.buffer == "cmd2"

      GenServer.cast(server_pid, {:keypress, [{:key, :up}]})
      state = Server.get_state(server_pid)
      assert state.buffer == "cmd1"

      # Navigate down
      GenServer.cast(server_pid, {:keypress, [{:key, :down}]})
      state = Server.get_state(server_pid)
      assert state.buffer == "cmd2"

      # Navigate back to original buffer
      GenServer.cast(server_pid, {:keypress, [{:key, :down}]})
      state = Server.get_state(server_pid)
      assert state.buffer == ""
    end

    test "handles tab with single completion" do
      server_pid = start_server()
      GenServer.cast(server_pid, {:keypress, [{:char, "h"}, {:char, "e"}]})
      GenServer.cast(server_pid, {:keypress, [{:key, :tab}]})
      state = Server.get_state(server_pid)
      assert state.buffer == "hello"
      assert state.cursor_pos == 5
    end

    test "handles tab with multiple completions" do
      server_pid = start_server()
      GenServer.cast(server_pid, {:keypress, [{:char, "h"}]})
      GenServer.cast(server_pid, {:keypress, [{:key, :tab}]})
      state = Server.get_state(server_pid)
      # Buffer should not change
      assert state.buffer == "h"
    end

    test "handles enter to process command" do
      server_pid = start_server()
      GenServer.cast(server_pid, {:keypress, [{:char, "hello"}, {:key, :enter}]})
      state = Server.get_state(server_pid)
      assert state.buffer == ""
      assert state.cursor_pos == 0
      assert state.history == ["hello"]
    end
  end
end