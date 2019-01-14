defmodule Kubernetex.Cluster.Version do
  defstruct [
    :build_date,
    :compiler,
    :git_commit,
    :git_tree_state,
    :git_version,
    :go_version,
    :major,
    :minor,
    :platform
  ]

  def parse(data) do
    "v" <> version = MapX.get(data, :gitVersion)

    with {:ok, build_date} <- Kubernetex.Primitives.Timestamp.parse(MapX.get(data, :buildDate)),
         {:ok, version} <- Version.parse(version) do
      {:ok,
       %__MODULE__{
         build_date: build_date,
         compiler: MapX.get(data, :compiler),
         git_commit: MapX.get(data, :gitCommit),
         git_tree_state: MapX.get(data, :gitTreeState),
         git_version: version,
         go_version: MapX.get(data, :goVersion),
         major: String.to_integer(MapX.get(data, :major)),
         minor: String.to_integer(MapX.get(data, :minor)),
         platform: MapX.get(data, :platform)
       }}
    end
  end

  defimpl Inspect, for: __MODULE__ do
    import Inspect.Algebra

    def inspect(%{git_version: version}, _opts) do
      concat(["#Version<", to_string(version), ">"])
    end
  end
end
