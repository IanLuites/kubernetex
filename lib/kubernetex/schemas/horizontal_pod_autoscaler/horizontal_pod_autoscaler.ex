defmodule Kubernetex.HorizontalPodAutoscaler do
  @moduledoc ~S"""
  """
  use Kubernetex.Structure

  defstructure version: "autoscaling/v1", kind: "HorizontalPodAutoscaler" do
    field :spec, __MODULE__.Spec, required: true
    field :metadata, Kubernetex.Metadata, required: true
  end
end
