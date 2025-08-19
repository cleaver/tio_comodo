defmodule TioComodo.Repl.ServerTest do
  use ExUnit.Case, async: false

  alias TioComodo.Repl.Server

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

  setup do
    {:ok, server_pid} = Server.start_link(
      prompt: "test> ",
      provider: MockProvider,
      name: :test_repl
    )

    # Give the server a moment to initialize
    Process.sleep(10)

    on_exit(fn ->
      try do
        GenServer.stop(server_pid, :normal)
      catch
        :exit, _ -> :ok
      end
    end)

    {:ok, server_pid: server_pid}
  end

  describe "server initialization" do
    test "starts with correct initial state", %{server_pid: server_pid} do
      state = Server.get_state(server_pid)

      assert state.prompt == "test> "
      assert state.provider == MockProvider
      assert state.buffer == ""
      assert state.cursor_pos == 0
      assert is_pid(state.reader_pid)
    end
  end

  describe "handle_event/2" do
    test "handles character input", %{server_pid: server_pid} do
      GenServer.cast(server_pid, {:keypress, [{:char, "a"}]})
      state = Server.get_state(server_pid)
      assert state.buffer == "a"
      assert state.cursor_pos == 1

      GenServer.cast(server_pid, {:keypress, [{:char, "b"}]})
      state = Server.get_state(server_pid)
      assert state.buffer == "ab"
      assert state.cursor_pos == 2
    end

    test "handles backspace", %{server_pid: server_pid} do
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

    test "handles left and right arrow keys", %{server_pid: server_pid} do
      GenServer.cast(server_pid, {:keypress, [{:char, "a"}, {:char, "b"}]})
      GenServer.cast(server_pid, {:keypress, [{:key, :left}]})
      state = Server.get_state(server_pid)
      assert state.cursor_pos == 1

      GenServer.cast(server_pid, {:keypress, [{:key, :right}]})
      state = Server.get_state(server_pid)
      assert state.cursor_pos == 2
    end

    test "handles home and end keys", %{server_pid: server_pid} do
      GenServer.cast(server_pid, {:keypress, [{:char, "a"}, {:char, "b"}]})
      GenServer.cast(server_pid, {:keypress, [{:key, :home}]})
      state = Server.get_state(server_pid)
      assert state.cursor_pos == 0

      GenServer.cast(server_pid, {:keypress, [{:key, :end}]})
      state = Server.get_state(server_pid)
      assert state.cursor_pos == 2
    end

    test "handles up and down arrow for history", %{server_pid: server_pid} do
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

    test "handles tab with single completion", %{server_pid: server_pid} do
      GenServer.cast(server_pid, {:keypress, [{:char, "h"}, {:char, "e"}]})
      GenServer.cast(server_pid, {:keypress, [{:key, :tab}]})
      state = Server.get_state(server_pid)
      assert state.buffer == "hello"
      assert state.cursor_pos == 5
    end

    test "handles tab with multiple completions", %{server_pid: server_pid} do
      GenServer.cast(server_pid, {:keypress, [{:char, "h"}]})
      GenServer.cast(server_pid, {:keypress, [{:key, :tab}]})
      state = Server.get_state(server_pid)
      # Buffer should not change
      assert state.buffer == "h"
    end

    test "handles enter to process command", %{server_pid: server_pid} do
      GenServer.cast(server_pid, {:keypress, [{:char, "hello"}, {:key, :enter}]})
      state = Server.get_state(server_pid)
      assert state.buffer == ""
      assert state.cursor_pos == 0
      assert state.history == ["hello"]
    end
  end
end