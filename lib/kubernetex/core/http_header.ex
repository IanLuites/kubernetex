defmodule Kubernetex.Core.HTTPHeader do
  @moduledoc ~S"""
  HTTPHeader describes a custom header to be used in HTTP probes
  """
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :name, :string, required: true
    field :value, :string, required: true
  end
end
