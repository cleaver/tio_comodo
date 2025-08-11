defmodule TioComodo.Repl.Helpers.History do
  @moduledoc """
  Helpers for REPL history naming and discovery.

  Provides functions to determine the basename of the history file, resolve the
  history file path, and load/persist history entries.
  """

  @doc """
  Returns the configured or inferred history file basename.

  Examples: "temp_cli_history", "my_app_history"
  """
  @spec history_basename() :: String.t()
  def history_basename do
    configured = Application.get_env(:temp_cli, :repl_history_basename)
    configured || default_history_basename()
  end

  @doc false
  @spec default_history_basename() :: String.t()
  def default_history_basename do
    case :application.get_application(self()) do
      {:ok, app} ->
        Atom.to_string(app) <> "_history"

      :undefined ->
        case Application.get_application(__MODULE__) do
          nil -> "history"
          app -> Atom.to_string(app) <> "_history"
        end
    end
  end

  @doc """
  Returns the absolute path to the history file, ensuring the directory exists.
  """
  @spec history_file_path() :: String.t()
  def history_file_path do
    base_dir =
      System.get_env("XDG_STATE_HOME") ||
        Path.join([System.user_home!(), ".local", "state"])

    dir = Path.join(base_dir, "tio_comodo")
    # Ensure directory exists; ignore errors
    _ = File.mkdir_p(dir)
    Path.join(dir, history_basename())
  end

  @doc """
  Loads the history from the history file.
  """
  @spec load_history() :: [String.t()]
  def load_history do
    path = history_file_path()

    case File.read(path) do
      {:ok, content} ->
        content
        |> String.split("\n", trim: true)
        |> Enum.reject(&(&1 == ""))

      {:error, _} ->
        []
    end
  end

  @doc """
  Appends an item to the history file. No-op for empty values.
  """
  @spec persist_history_item(String.t()) :: :ok
  def persist_history_item(item) when is_binary(item) and item != "" do
    path = history_file_path()
    # Best-effort append; ignore errors
    _ = File.write(path, item <> "\n", [:append])
    :ok
  end

  def persist_history_item(_), do: :ok
end
