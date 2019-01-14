defmodule Kubernetex.Namespace.Status do
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :phase, {:enum, [:active, :terminating]}, required: true
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{phase: :active}, _opts), do: "#Status<Active>"
    def inspect(%{phase: :terminating}, _opts), do: "#Status<Terminating>"
  end
end
