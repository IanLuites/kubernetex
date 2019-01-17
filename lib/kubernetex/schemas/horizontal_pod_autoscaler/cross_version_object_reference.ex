defmodule Kubernetex.CrossVersionObjectReference do
  @moduledoc ~S"""

  """
  use Kubernetex.Structure

  defstructure version: "autoscaling/v1" do
    field :api_version, :string, required: true
    field :kind, :string, required: true
    field :name, :string, required: true
  end
end
