defmodule TioComodo.MixProject do
  use Mix.Project

  @source_url "https://github.com/user/repo"

  def project do
    [
      app: :tio_comodo,
      version: "0.1.0",
      elixir: "~> 1.18",
      deps: deps(),

      name: "Tio Comodo",
      source_url: @source_url,
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  defp deps do
    [
      {:owl, "~> 0.12"},
      {:ucwidth, "~> 0.2"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
    ]
  end
end
