defmodule Kubernetex.StatefulSet.Condition do
  use Kubernetex.Structure

  defstructure version: "app/v1" do
    field :last_transition_time, :timestamp, required: true
    field :message, :string, required: true
    field :reason, :reason, required: true
    field :status, :status, required: true
    field :type, :condition_type, required: true
  end
end
