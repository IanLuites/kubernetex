defmodule Kubernetex.Pod do
  use Kubernetex.Structure

  defstructure version: "core/v1", kind: "Pod" do
    field :metadata, Kubernetex.Metadata, required: true
    field :status, __MODULE__.Status, required: true
  end
end
