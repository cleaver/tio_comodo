defmodule TioComodo.Repl.Provider.Behaviour do
  @moduledoc """
  Defines the behaviour for a REPL command provider.
  """

  @doc """
  Dispatches a command and returns the result.
  """
  @callback dispatch(command :: String.t()) ::
              {:ok, String.t()}
              | {:error, String.t()}
              | {:stop, any(), String.t()}

  @doc """
  Provides a list of completion suggestions for the given buffer and cursor position.
  """
  @callback completions(buffer :: String.t(), cursor_pos :: non_neg_integer()) :: [String.t()]
end
