defmodule Kubernetex.Container.Resources do
  alias Kubernetex.{CPU, Memory}

  defstruct [
    :limits,
    :requests
  ]

  def parse(data) when is_map(data) do
    with {:ok, limits} <- parse_resource(MapX.get(data, :limits)),
         {:ok, requests} <- parse_resource(MapX.get(data, :requests)) do
      {:ok,
       %__MODULE__{
         limits: limits,
         requests: requests
       }}
    end
  end

  def parse(_), do: {:error, :invalid_resources_specification}

  defp parse_resource(nil), do: {:ok, nil}

  defp parse_resource(data) do
    cpu = MapX.get(data, :cpu)
    memory = MapX.get(data, :memory)

    cond do
      memory && cpu ->
        with {:ok, memory} <- Kubernetex.Memory.parse(memory),
             {:ok, cpu} <- Kubernetex.CPU.parse(cpu) do
          {:ok, %{cpu: cpu, memory: memory}}
        end

      memory ->
        with {:ok, memory} <- Memory.parse(memory), do: {:ok, %{memory: memory}}

      cpu ->
        with {:ok, cpu} <- CPU.parse(cpu), do: {:ok, %{cpu: cpu}}

      :no_resources ->
        {:ok, nil}
    end
  end

  def dump(resources, _opts \\ []) do
    resources
    |> Map.from_struct()
    |> MapX.new(fn
      {_, nil} -> :skip
      {k, v} -> {:ok, k, v}
    end)
  end
end
