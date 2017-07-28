defmodule Kubex.Namespace do
  @doc false
  def __resource__ do
    "namespaces"
  end

  @doc false
  def __default__ do
    %{
      kind: __MODULE__,
      apiVersion: :v1,
    }
  end

  # apiVersion: v1
  # kind: Namespace
  # metadata:
  #   name: nginx-ingress

end
