defmodule TioComodo.ColorschemeTest do
  use ExUnit.Case, async: true

  alias TioComodo.Colorscheme

  setup do
    # Ensure a clean slate for each test
    Application.delete_env(:tio_comodo, :colorscheme)
    :ok
  end

  describe "get_colorscheme/0" do
    test "returns default colorscheme when no config is set" do
      colorscheme = Colorscheme.get_colorscheme()

      assert colorscheme.user == :green
      assert colorscheme.prompt == :blue
      assert colorscheme.error == :red
    end

    test "merges user config over defaults using atoms" do
      Application.put_env(:tio_comodo, :colorscheme, %{
        user: :magenta,
        prompt: :cyan
      })

      colorscheme = Colorscheme.get_colorscheme()

      # Custom colors should override defaults
      assert colorscheme.user == :magenta
      assert colorscheme.prompt == :cyan

      # Other colors should remain as defaults
      assert colorscheme.error == :red
    end
  end

  describe "colorize/2" do
    test "applies the correct default color to text" do
      text = "Hello"
      color_key = :success # Default is :green
      expected_output = Owl.Data.tag(text, :green) |> Owl.Data.to_chardata() |> to_string()

      assert Colorscheme.colorize(text, color_key) == expected_output
    end

    test "applies a user-configured color to text" do
      Application.put_env(:tio_comodo, :colorscheme, %{error: :light_white})

      text = "Error message"
      color_key = :error
      expected_output =
        Owl.Data.tag(text, :light_white) |> Owl.Data.to_chardata() |> to_string()

      assert Colorscheme.colorize(text, color_key) == expected_output
    end

    test "falls back to a default color for an unknown key" do
      text = "Unknown"
      color_key = :some_unknown_key
      # The fallback color is :white
      expected_output = Owl.Data.tag(text, :white) |> Owl.Data.to_chardata() |> to_string()

      assert Colorscheme.colorize(text, color_key) == expected_output
    end
  end
end
