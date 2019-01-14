defmodule Kubernetex.Deployment.Selector do
  use Kubernetex.Structure

  # selector:
  #   matchLabels:
  #     app: nginx

  defstructure version: "app/v1" do
    field :match_labels, :map, required: true
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{match_labels: l}, _opts) do
      "#Selector<#{l |> Enum.map(fn {k, v} -> "#{k}:#{v}" end) |> Enum.join(",")}>"
    end
  end
end
