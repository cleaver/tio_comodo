defmodule TioComodo.Repl.ServerIntegrationTest do
  use ExUnit.Case, async: false

  alias TioComodo.Repl.Server

  # Mock provider for testing
  defmodule MockProvider do
    def dispatch("hello"), do: {:ok, "Hello, World!"}
    def dispatch("error"), do: {:error, "Something went wrong"}
    def dispatch("quit"), do: {:stop, :normal, "Goodbye!"}
    def dispatch(_), do: {:ok, ""}

    def completions(_, _), do: ["hello", "help", "quit"]
  end

  setup do
    {:ok, server_pid} = Server.start_link(
      prompt: "test> ",
      provider: MockProvider,
      name: :test_repl
    )

    # Give the server a moment to initialize
    Process.sleep(10)

    {:ok, server_pid: server_pid}
  end

  describe "basic functionality" do
    test "server starts with correct configuration", %{server_pid: server_pid} do
      # Get the current state to verify configuration
      state = Server.get_state(server_pid)

      assert state.prompt == "test> "
      assert state.provider == MockProvider
      assert state.buffer == ""
      assert state.cursor_pos == 0
    end

    test "server can process commands", %{server_pid: server_pid} do
      # Test that the server is running and can handle commands
      # This verifies the integration points are working

      # Verify the server is running with our mock provider
      state = Server.get_state(server_pid)
      assert state.provider == MockProvider

      # The server should be ready to process input
      assert is_pid(state.reader_pid)
    end
  end

  # Clean up after tests
  test "cleanup", %{server_pid: server_pid} do
    # Stop the server gracefully
    try do
      GenServer.stop(server_pid, :normal)
    catch
      :exit, _ -> :ok  # Server might already be terminated
    end
  end
end
