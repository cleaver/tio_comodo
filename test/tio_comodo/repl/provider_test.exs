defmodule TioComodo.Repl.ProviderTest do
  use ExUnit.Case, async: true

  alias TioComodo.Repl.Provider

  # 1. Define a mock command module directly in the test file.
  defmodule TestCommands do
    def commands do
      %{
        "ping" => {__MODULE__, :ping, []},
        "echo" => {__MODULE__, :echo, []},
        "stop" => {__MODULE__, :stop, []}
      }
    end

    def ping(_args), do: {:ok, "pong"}
    def echo(args), do: {:ok, Enum.join(args, " ")}
    def stop(_args), do: {:stop, :test_stop, "stopping"}
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

    test "returns an error for an unknown command" do
      assert Provider.dispatch("unknown_command") == {:error, "Unknown command: unknown_command"}
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
    end

    test "returns completions that match the buffer" do
      assert Provider.completions("p", 1) == ["ping"]
      assert Provider.completions("e", 1) == ["echo"]
    end

    test "returns no completions if nothing matches" do
      assert Provider.completions("z", 1) == []
    end
  end
end
