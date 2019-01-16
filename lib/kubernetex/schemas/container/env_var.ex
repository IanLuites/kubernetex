defmodule Kubernetex.Container.EnvVar do
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :name, :string, required: true
    field :value, :string, required: true
  end
end
