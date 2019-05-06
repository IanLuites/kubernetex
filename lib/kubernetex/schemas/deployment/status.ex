defmodule Kubernetex.Deployment.Status do
  use Kubernetex.Structure

  defstructure version: "app/v1" do
    field :collision_count, :non_neg_integer, required: false, default: 0
    field :observed_generation, :non_neg_integer, required: false, default: 0
    field :replicas, :non_neg_integer, required: false, default: 0
    field :available_replicas, :non_neg_integer, required: false, default: 0
    field :unavailable_replicas, :non_neg_integer, required: false, default: 0
    field :ready_replicas, :non_neg_integer, required: false, default: 0
    field :updated_replicas, :non_neg_integer, required: false, default: 0
    field :conditions, {:array, Kubernetex.Deployment.Condition}, required: false, default: []
  end
end
