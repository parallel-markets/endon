defmodule Endon.MixProject do
  use Mix.Project

  @source_url "https://github.com/parallel-markets/endon"
  @version "2.0.2"

  def project do
    [
      app: :endon,
      aliases: aliases(),
      version: @version,
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Ecto query helpers, inspired by ActiveRecord",
      package: package(),
      docs: docs(),
      preferred_cli_env: [test: :test, "ci.test": :test]
    ]
  end

  defp aliases do
    [
      "ci.test": [
        "format --check-formatted",
        "credo",
        "test"
      ]
    ]
  end

  def package do
    [
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md),
      maintainers: ["Brian Muller"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md",
        "GitHub" => @source_url
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ecto, "~> 3.8"},
      {:ex_doc, "~> 0.28", only: :dev},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      extra_section: "GUIDES",
      source_ref: "v#{@version}",
      source_url: @source_url,
      main: "readme",
      formatters: ["html"],
      extras: [
        "README.md",
        "guides/features.md"
      ]
    ]
  end
end
