defmodule TioComodo.ColorschemeTest do
  use ExUnit.Case, async: true

  alias TioComodo.Colorscheme

  describe "get_colorscheme/0" do
    test "returns default colorscheme when no config" do
      # Clear any existing config for this test
      Application.delete_env(:tio_comodo, :colourscheme)

      colorscheme = Colorscheme.get_colorscheme()

      assert colorscheme.user == :green
      assert colorscheme.prompt == :blue
      assert colorscheme.error == :red
      assert colorscheme.success == :green
      assert colorscheme.warning == :yellow
      assert colorscheme.info == :blue
      assert colorscheme.completion == :cyan
    end

    test "merges user config over defaults" do
      # Set custom config
      Application.put_env(:tio_comodo, :colourscheme, %{
        user: "magenta",
        prompt: "cyan"
      })

      colorscheme = Colorscheme.get_colorscheme()

      # Custom colors should override defaults
      assert colorscheme.user == "magenta"
      assert colorscheme.prompt == "cyan"

      # Other colors should remain as defaults
      assert colorscheme.error == :red
      assert colorscheme.success == :green
      assert colorscheme.warning == :yellow
      assert colorscheme.info == :blue
      assert colorscheme.completion == :cyan

      # Clean up
      Application.delete_env(:tio_comodo, :colourscheme)
    end
  end

  describe "colorize/2" do
    test "applies correct color to text" do
      # Test that colorize returns text wrapped in ANSI color codes
      colored_text = Colorscheme.colorize("Hello", :success)

      # The result should be a string containing the text and color information
      assert is_binary(colored_text)
      assert colored_text != "Hello"  # Should be different due to color codes
    end

    test "handles different color keys" do
      error_text = Colorscheme.colorize("Error message", :error)
      warning_text = Colorscheme.colorize("Warning message", :warning)
      info_text = Colorscheme.colorize("Info message", :info)

      assert is_binary(error_text)
      assert is_binary(warning_text)
      assert is_binary(info_text)
      assert error_text != warning_text
      assert warning_text != info_text
    end
  end

  describe "get_color/1" do
    test "returns configured color or default" do
      # Test with default colors
      assert Colorscheme.get_color(:user) == :green
      assert Colorscheme.get_color(:prompt) == :blue
      assert Colorscheme.get_color(:error) == :red

      # Test with custom config
      Application.put_env(:tio_comodo, :colourscheme, %{
        user: :yellow,
        custom_color: :purple
      })

      assert Colorscheme.get_color(:user) == :yellow
      assert Colorscheme.get_color(:custom_color) == :purple

      # Test fallback to default for unknown color
      assert Colorscheme.get_color(:unknown_color) == :white

      # Clean up
      Application.delete_env(:tio_comodo, :colourscheme)
    end
  end
end
