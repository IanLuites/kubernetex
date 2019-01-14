defmodule Kubernetex.Deployment.Spec do
  use Kubernetex.Structure

  # replicas: 3
  # selector:
  #   matchLabels:
  #     app: nginx
  # template:
  #   metadata:
  #     labels:
  #       app: nginx
  #   spec:
  #     containers:
  #     - name: nginx
  #       image: nginx:1.7.9
  #       ports:
  #       - containerPort: 80

  defstructure version: "app/v1" do
    field :replicas, Kubernetex.Replicas, required: true
    field :selector, Kubernetex.Deployment.Selector, required: true
    field :template, Kubernetex.Template, required: true
  end

  # defimpl Inspect, for: __MODULE__ do
  #   def inspect(%{finalizers: f}, _opts), do: "#Finalizers<#{Enum.join(f, ",")}>"
  # end
end
