defmodule Kubernetex.Ingress.Rules.HTTP do
  @moduledoc ~S"""

  """
  use Kubernetex.Structure

  defstructure version: "extensions/v1beta1" do
    field :paths, {:array, Kubernetex.Ingress.Path}, required: false, default: []
  end
end
