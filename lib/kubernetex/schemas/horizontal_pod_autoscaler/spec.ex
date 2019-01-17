defmodule Kubernetex.HorizontalPodAutoscaler.Spec do
  @moduledoc ~S"""

  """
  use Kubernetex.Structure

  defstructure version: "autoscaling/v1" do
    field :min_replicas, :non_neg_integer, required: true
    field :max_replicas, :non_neg_integer, required: true

    field :target_cpu_utilization_percentage, :non_neg_integer,
      required: true,
      camelized: :targetCPUUtilizationPercentage

    field :scale_target_ref, Kubernetex.CrossVersionObjectReference, required: true
  end

  def validate(
        spec = %__MODULE__{
          min_replicas: min,
          max_replicas: max,
          target_cpu_utilization_percentage: cpu
        }
      ) do
    cond do
      max <= min -> {:error, :max_replicas_lower_or_equal_to_min}
      min <= 0 -> {:error, :min_replicas_must_at_least_be_one}
      cpu <= 0 or cpu >= 100 -> {:error, :cpu_percentage_out_of_range}
      :valid -> {:ok, spec}
    end
  end
end
