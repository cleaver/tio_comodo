defmodule TioComodo.Repl.RenderTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO

  alias TioComodo.Repl.Render
  alias TioComodo.Colorscheme

  describe "redraw/1" do
    test "produces the correct sequence of ANSI codes for drawing the line" do
      state = %{
        prompt: "test> ",
        buffer: "hello",
        cursor_pos: 5
      }

      # Expected sequence:
      # 1. \r       (move to beginning of line)
      # 2. \e[K      (clear line)
      # 3. <prompt> (colored)
      # 4. <buffer>
      # 5. \e[<n>D  (move cursor back, if needed)
      # In this case, cursor is at the end, so no move back is needed.
      prompt_colored = Colorscheme.colorize("test> ", :prompt)
      expected_output = "\r\e[K" <> prompt_colored <> "hello"

      output = capture_io(fn -> Render.redraw(state) end)
      assert output == expected_output
    end

    test "positions cursor correctly when not at the end of the buffer" do
      state = %{
        prompt: "test> ",
        buffer: "hello world",
        cursor_pos: 5
      }

      prompt_colored = Colorscheme.colorize("test> ", :prompt)
      # 11 (buffer length) - 5 (cursor_pos) = 6 chars to move back
      expected_output = "\r\e[K" <> prompt_colored <> "hello world" <> "\e[6D"

      output = capture_io(fn -> Render.redraw(state) end)
      assert output == expected_output
    end
  end

  describe "print_completions/1" do
    test "formats completions and moves cursor back to original line" do
      completions = ["hello", "help"]
      bullet = Colorscheme.colorize("  • ", :completion)

      # Expected sequence:
      # 1. \r\n (newline)
      # 2. <bullet> completion1 \r\n
      # 3. <bullet> completion2 \r\n
      # 4. \e[<n>A (move cursor up n lines)
      # n = number of completions + 1
      expected_output =
        "\r\n" <> 
          bullet <> "hello\r\n" <> 
          bullet <> "help\r\n" <> 
          "\e[3A"

      output = capture_io(fn -> Render.print_completions(completions) end)
      assert output == expected_output
    end

    test "handles empty completions list" do
      output = capture_io(fn -> Render.print_completions([]) end)
      assert output == ""
    end
  end

  describe "colored message functions" do
    test "print_error outputs colored message without extra newlines" do
      expected = Colorscheme.colorize("Test error", :error)
      output = capture_io(fn -> Render.print_error("Test error") end)
      assert output == expected
    end

    test "print_success outputs colored message with surrounding newlines" do
      expected = Colorscheme.colorize("Test success", :success) <> "\r\n"
      output = capture_io(fn -> Render.print_success("Test success") end)
      assert output == expected
    end

    test "print_info outputs colored message with surrounding newlines" do
      expected = Colorscheme.colorize("Test info", :info) <> "\r\n"
      output = capture_io(fn -> Render.print_info("Test info") end)
      assert output == expected
    end

    test "print_command outputs colored message with surrounding newlines" do
      expected = "\r\n" <> Colorscheme.colorize("my command", :user) <> "\r\n"
      output = capture_io(fn -> Render.print_command("my command") end)
      assert output == expected
    end
  end

  describe "terminal output helpers" do
    test "newline/0 prints a carriage return and line feed" do
      assert capture_io(fn -> Render.newline() end) == "\r\n"
    end

    test "home_cursor/0 prints a carriage return" do
      assert capture_io(fn -> Render.home_cursor() end) == "\r"
    end

    test "clear_line/0 prints the clear line ANSI code" do
      assert capture_io(fn -> Render.clear_line() end) == "\e[K"
    end

    test "move_cursor_up/1 prints the correct ANSI code" do
      assert capture_io(fn -> Render.move_cursor_up(5) end) == "\e[5A"
    end

    test "move_cursor_back/1 prints the correct ANSI code" do
      assert capture_io(fn -> Render.move_cursor_back(3) end) == "\e[3D"
    end
  end
end