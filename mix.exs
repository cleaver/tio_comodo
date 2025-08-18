defmodule TioComodo.MixProject do
  use Mix.Project

  def project do
    [
      app: :tio_comodo,
      version: "0.1.0",
      elixir: "~> 1.18",
      deps: deps()
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:owl, "~> 0.12"},
      {:ucwidth, "~> 0.2"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
