defmodule Kubex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :kubex,
      description: "Kubernetes library for Elixir.",
      version: "0.0.1",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),

      # Docs
      name: "Kubex",
      source_url: "https://github.com/IanLuites/kubex",
      homepage_url: "https://github.com/IanLuites/kubex",
      docs: [
        main: "readme",
        extras: ["README.md"],
      ],
    ]
  end

  def package do
    [
      name: :kubex,
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      files: [
        "lib/kubex", "lib/kubex.ex", "lib/util.ex", "mix.exs", "README*", "LICENSE*", # Elixir
      ],
      links: %{
        "GitHub" => "https://github.com/IanLuites/kubex",
      },
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:httpx, "~> 0.0"},

      # Dev / Test
      {:analyze, ">= 0.0.6", only: [:dev, :test], runtime: false},
    ]
  end
end
