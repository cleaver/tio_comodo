defmodule TioComodo.Repl.ProviderTest do
  use ExUnit.Case, async: true

  alias TioComodo.Repl.Provider

  # 1. Define a mock command module directly in the test file.
  defmodule TestCommands do
    def commands do
      %{
        "ping" => {__MODULE__, :ping, []},
        "echo" => {__MODULE__, :echo, []},
        "stop" => {__MODULE__, :stop, []},
        "catchall_handler" => {__MODULE__, :handle_catchall, []}
      }
    end

    def ping(_args), do: {:ok, "pong"}
    def echo(args), do: {:ok, Enum.join(args, " ")}
    def stop(_args), do: {:stop, :test_stop, "stopping"}
    def handle_catchall(input), do: {:ok, "Catchall handled: #{input}"}
  end

  # 2. Use the setup block to configure the application environment for each test.
  setup do
    # Point the :simple_provider to our test module's function.
    Application.put_env(:tio_comodo, :simple_provider, {TestCommands, :commands})
    :ok
  end

  describe "dispatch/1" do
    test "dispatches a known command without arguments" do
      assert Provider.dispatch("ping") == {:ok, "pong"}
    end

    test "dispatches a known command with arguments" do
      assert Provider.dispatch("echo hello world") == {:ok, "hello world"}
    end

    test "calls catchall handler for unknown commands" do
      assert Provider.dispatch("unknown_command") == {:ok, "Catchall handled: unknown_command"}
    end

    test "handles empty input" do
      assert Provider.dispatch("") == {:ok, ""}
    end

    test "handles commands that signal to stop" do
      assert Provider.dispatch("stop") == {:stop, :test_stop, "stopping"}
    end
  end

  describe "completions/2" do
    test "returns a list of all commands for an empty buffer" do
      completions = Provider.completions("", 0)
      assert "ping" in completions
      assert "echo" in completions
      assert "stop" in completions
      # Ensure catchall_handler is not included in completions
      refute "catchall_handler" in completions
    end

    test "returns completions that match the buffer" do
      assert Provider.completions("p", 1) == ["ping"]
      assert Provider.completions("e", 1) == ["echo"]
    end

    test "returns no completions if nothing matches" do
      assert Provider.completions("z", 1) == []
    end
  end

  describe "catchall_handler from command map" do
    test "calls catchall handler for unknown commands" do
      assert Provider.dispatch("unknown_command arg1 arg2") == {:ok, "Catchall handled: unknown_command arg1 arg2"}
    end

    test "calls catchall handler with the full input string" do
      assert Provider.dispatch("some random input") == {:ok, "Catchall handled: some random input"}
    end

    test "still dispatches known commands normally when catchall is configured" do
      assert Provider.dispatch("ping") == {:ok, "pong"}
      assert Provider.dispatch("echo hello") == {:ok, "hello"}
    end
  end

  describe "without catchall_handler in command map" do
    defmodule TestCommandsNoCatchall do
      def commands do
        %{
          "ping" => {__MODULE__, :ping, []},
          "echo" => {__MODULE__, :echo, []}
        }
      end

      def ping(_args), do: {:ok, "pong"}
      def echo(args), do: {:ok, Enum.join(args, " ")}
    end

    test "returns error for unknown commands when no catchall is configured" do
      Application.put_env(:tio_comodo, :simple_provider, {TestCommandsNoCatchall, :commands})
      assert Provider.dispatch("unknown_command") == {:error, "Unknown command: unknown_command"}
    end
  end
end
