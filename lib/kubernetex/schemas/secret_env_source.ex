defmodule Kubernetex.SecretEnvSource do
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :name, :string, required: true
    field :optional, :boolean, required: false
  end
end
