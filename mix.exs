defmodule Elastic.Mixfile do
  use Mix.Project
  @version "3.6.2"

  def project do
    [
      app: :elastic,
      version: @version,
      elixir: "~> 1.10",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      # Docs
      name: "Elastic",
      docs: [
        source_ref: "v#{@version}",
        main: "Elastic",
        canonical: "http://hexdocs.pm/elastic",
        source_url: "https://github.com/radar/elastic"
      ],
      dialyzer: [
        plt_core_path: "priv/plts",
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix]
      ],
      deps: deps()
    ]
  end

  def application do
    [
      applications: [:logger, :tesla, :hackney, :aws_auth, :jason]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:tesla, "~> 1.5"},
      {:hackney, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:aws_auth, "~> 0.7.1"},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev},

      # Property-based testing
      {:stream_data, "~> 0.5", only: [:dev, :test]}
    ]
  end

  defp package do
    [
      name: :elastic,
      description: "You Know, for (Elastic) Search",
      files: ["lib", "README*", "mix.exs"],
      maintainers: ["Ryan Bigg", "Flexibility.ai"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/flexibility-org/elastic"}
    ]
  end
end
