defmodule Kubernetex.Namespace do
  use Kubernetex.Structure

  defstructure version: "core/v1", kind: "Namespace" do
    field :metadata, Kubernetex.Metadata, required: true
    field :status, __MODULE__.Status, required: false
    field :spec, __MODULE__.Spec, required: false
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{metadata: %{name: name}}, _opts), do: "#Namespace<#{name}>"
  end
end
