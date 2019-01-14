defmodule Kubernetex.Ingress.Rule do
  @moduledoc ~S"""

  """
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :host, :string, required: false
  end
end
