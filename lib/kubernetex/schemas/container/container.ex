defmodule Kubernetex.Container do
  use Kubernetex.Structure

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

  defstructure version: "core/v1" do
    field :name, :string, required: true
    field :image, Kubernetex.Docker, required: true
    field :ports, {:array, __MODULE__.Port}, required: false, default: []
  end
end
