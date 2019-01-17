defmodule Kubernetex.Ingress.Rule do
  @moduledoc ~S"""

  """
  use Kubernetex.Structure

  defstructure version: "extensions/v1beta1" do
    field :host, :string, required: false
    field :http, Kubernetex.Ingress.Rules.HTTP, required: true
  end
end
