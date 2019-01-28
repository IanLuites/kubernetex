defmodule Kubernetex.LocalObjectReference do
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :name, :string, required: true
  end
end
