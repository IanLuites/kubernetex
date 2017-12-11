defmodule Kubex.Pod do
  @doc false
  def __resource__ do
    "pods"
  end

  @doc false
  def __default__ do
    %{
      kind: __MODULE__,
      apiVersion: :v1
    }
  end
end
