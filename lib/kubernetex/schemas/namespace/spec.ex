defmodule Kubernetex.Namespace.Spec do
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :finalizers, {:array, :string}, required: true
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{finalizers: f}, _opts), do: "#Finalizers<#{Enum.join(f, ",")}>"
  end
end
