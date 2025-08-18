defmodule TioComodo.Repl.RenderTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias TioComodo.Repl.Render

  describe "redraw/1" do
    test "displays colored prompt correctly" do
      state = %{
        prompt: "test> ",
        buffer: "hello world",
        cursor_pos: 5
      }

      # Capture IO output
      output = capture_io(fn -> Render.redraw(state) end)

      # Should contain the prompt and buffer
      assert output =~ "test> "
      assert output =~ "hello world"

      # Should contain cursor positioning
      assert output =~ "\e[6D"  # Move back 6 characters (11 - 5)
    end

    test "positions cursor correctly after colored prompt" do
      state = %{
        prompt: "test> ",
        buffer: "hello world",
        cursor_pos: 5
      }

      output = capture_io(fn -> Render.redraw(state) end)

      # Should contain cursor positioning
      assert output =~ "\e[6D"  # Move back 6 characters (11 - 5)
    end
  end

  describe "print_completions/1" do
    test "shows colored bullet points" do
      completions = ["hello", "help", "history"]

      output = capture_io(fn -> Render.print_completions(completions) end)

      # Should contain bullet points and completions
      assert output =~ "  • "
      assert output =~ "hello"
      assert output =~ "help"
      assert output =~ "history"
    end

    test "handles empty completions list" do
      output = capture_io(fn -> Render.print_completions([]) end)

      # Should not output anything
      assert output == ""
    end
  end

  describe "colored message functions" do
    test "print_error outputs with error colors" do
      output = capture_io(fn -> Render.print_error("Test error") end)

      # Should contain the error message
      assert output =~ "Test error"

      # Should contain color codes (Owl generates ANSI codes)
      assert output != "Test error"  # Should be different due to color
    end

    test "print_success outputs with success colors" do
      output = capture_io(fn -> Render.print_success("Test success") end)

      # Should contain the success message
      assert output =~ "Test success"

      # Should contain color codes
      assert output != "Test success"
    end

    test "print_warning outputs with warning colors" do
      output = capture_io(fn -> Render.print_warning("Test warning") end)

      # Should contain the warning message
      assert output =~ "Test warning"

      # Should contain color codes
      assert output != "Test warning"
    end

    test "print_info outputs with info colors" do
      output = capture_io(fn -> Render.print_info("Test info") end)

      # Should contain the info message
      assert output =~ "Test info"

      # Should contain color codes
      assert output != "Test info"
    end
  end
end
