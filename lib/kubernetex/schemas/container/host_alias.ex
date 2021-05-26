defmodule Kubernetex.Container.HostAlias do
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :hostnames, {:array, :string}, required: true
    field :ip, :string, required: true
  end
end
