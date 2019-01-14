defmodule Kubernetex.Ingress do
  @moduledoc ~S"""
  """
  use Kubernetex.Structure

  defstructure version: "extensions/v1beta1", kind: "Ingress" do
    field :spec, __MODULE__.Spec, required: true
    field :metadata, Kubernetex.Metadata, required: true
  end
end
