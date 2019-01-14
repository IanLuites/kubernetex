defmodule Kubernetex.Cluster.API.Version do
  defstruct [
    :version,
    :group,
    preferred: false
  ]
end

defmodule Kubernetex.Cluster.API.Versions do
  defstruct [
    :core,
    :apis
  ]

  def preferred(%{core: core, apis: apis}) do
    core
    |> Kernel.++(apis)
    |> Enum.filter(& &1.preferred)
    |> Enum.map(& &1.group)
  end

  def preferred(%{core: core}, "core"),
    do: Enum.find_value(core, &if(&1.preferred, do: &1.version))

  def preferred(%{apis: apis}, api) do
    api = api <> "/"

    Enum.find_value(
      apis,
      &if(String.starts_with?(&1.group, api) and &1.preferred, do: &1.version)
    )
  end

  alias Kubernetex.Cluster.API
  alias Kubernetex.Cluster.API.Version, as: V

  def parse(config) do
    with {:ok, %{versions: versions}} <- API.get(config, "/api"),
         {:ok, %{groups: groups}} <- API.get(config, "/apis") do
      [v | vs] = Enum.map(versions, &%V{version: &1, group: "core/#{&1}"})

      {:ok,
       %__MODULE__{
         core: [Map.put(v, :preferred, true) | vs],
         apis:
           Enum.flat_map(groups, fn %{versions: versions, preferredVersion: %{version: preferred}} ->
             Enum.map(
               versions,
               &%V{
                 version: &1.version,
                 group: &1.groupVersion,
                 preferred: &1.version == preferred
               }
             )
           end)
       }}
    end
  end
end
