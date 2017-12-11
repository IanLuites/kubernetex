defmodule Kubex.ReplicaSet do
  @doc false
  def __resource__ do
    "replicasets"
  end

  @doc false
  def __default__ do
    %{
      kind: __MODULE__,
      apiVersion: :"extensions/v1beta1"
    }
  end
end
