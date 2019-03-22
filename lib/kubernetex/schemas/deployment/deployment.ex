defmodule Kubernetex.Deployment do
  use Kubernetex.Structure

  defstructure version: "apps/v1", kind: "Deployment" do
    field :metadata, Kubernetex.Metadata, required: true
    field :spec, __MODULE__.Spec, required: true
    field :status, __MODULE__.Status, required: false
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{metadata: %{name: name}}, _opts), do: "#Deployment<#{name}>"
  end
end
