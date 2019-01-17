defmodule Kubernetex.Ingress.Backend do
  @moduledoc ~S"""

  """
  use Kubernetex.Structure

  defstructure version: "extensions/v1beta1" do
    field :service_name, :string, required: true
    field :service_port, :port, required: true
  end
end
