defmodule TioComodo.Colorscheme do
  @moduledoc """
  Manages colorschemes for the TioComodo REPL interface.

  Provides a default Gruvbox-inspired colorscheme and allows users to
  configure custom colors via application configuration.
  """

  @doc """
  Returns the current colorscheme with user configuration merged over defaults.

  The default colorscheme uses Gruvbox-inspired colors that are easy on the eyes
  and provide good contrast in both light and dark terminals.
  """
  @spec get_colorscheme() :: map()
  def get_colorscheme do
    default_colorscheme()
    |> Map.merge(user_colorscheme())
  end

  @doc """
  Retrieves a specific color value from the current colorscheme.

  Returns the color string that can be used with Owl for styling.
  """
  @spec get_color(atom()) :: atom()
  def get_color(color_key) do
    get_colorscheme()
    |> Map.get(color_key, :white)
  end

  # Private functions

  defp default_colorscheme do
    %{
      user: :green,
      background: :black,
      prompt: :blue,
      error: :red,
      success: :green,
      warning: :yellow,
      info: :blue,
      completion: :cyan
    }
  end

  defp user_colorscheme do
    Application.get_env(:tio_comodo, :colourscheme, %{})
  end

  @doc """
  Applies color to text using the specified color key from the colorscheme.

  Returns the text wrapped in appropriate ANSI color codes using Owl.
  """
  @spec colorize(String.t(), atom()) :: String.t()
  def colorize(text, color_key) do
    color = get_color(color_key)
    Owl.Data.tag(text, color)
    |> Owl.Data.to_chardata()
    |> to_string()
  end
end
