defmodule TioComodoTest do
  use ExUnit.Case
  doctest TioComodo

  test "greets the world" do
    assert TioComodo.hello() == :world
  end
end
