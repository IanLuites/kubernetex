defmodule Kubernetex.Ingress.Path do
  @moduledoc ~S"""

  """
  use Kubernetex.Structure

  defstructure version: "extensions/v1beta1" do
    field :path, :string, required: false, default: nil
    field :backend, Kubernetex.Ingress.Backend, required: true
  end
end
