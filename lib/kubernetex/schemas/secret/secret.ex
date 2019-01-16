defmodule Kubernetex.Secret do
  @moduledoc ~S"""
  Kubernetes secret.
  """
  use Kubernetex.Structure

  defstructure version: "core/v1", kind: "Secret" do
    field :data, __MODULE__.Data, required: true
    field :metadata, Kubernetex.Metadata, required: true
  end
end
