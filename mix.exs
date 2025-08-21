defmodule TioComodo.MixProject do
  use Mix.Project

  @source_url "https://github.com/cleaver/tio_comodo"

  def project do
    [
      app: :tio_comodo,
      version: "0.1.2",
      elixir: "~> 1.18",
      deps: deps(),
      description: "A simple, embeddable REPL for Elixir applications.",
      package: [
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => @source_url}
      ],

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
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end
end
