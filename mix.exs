defmodule Kubernetex.MixProject do
  use Mix.Project

  @version "1.0.0-rc1"

  def project do
    [
      app: :kubernetex,
      description: "Kubernetes library for Elixir.",
      version: @version,
      elixir: "~> 1.7",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Docs
      name: "Kubernetex",
      source_url: "https://github.com/IanLuites/kubernetex",
      homepage_url: "https://github.com/IanLuites/kubernetex",
      docs: [
        main: "readme",
        extras: ["README.md"]
      ]
    ]
  end

  def package do
    [
      name: :kubernetex,
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      files: [
        # Elixir
        "lib/kubex",
        "lib/kubex.ex",
        "lib/util.ex",
        "mix.exs",
        "README*",
        "LICENSE*"
      ],
      links: %{
        "GitHub" => "https://github.com/IanLuites/kubernetex"
      }
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:common_x, "~> 0.0.5"},
      {:httpx, "~> 0.0.12"},
      {:jason, "~> 1.1"},
      {:yaml_elixir, "~> 2.1"},
    ]
  end
end
