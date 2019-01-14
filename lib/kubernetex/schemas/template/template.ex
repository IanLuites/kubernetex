defmodule Kubernetex.Template do
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
    field :metadata, Kubernetex.Metadata, required: true
    field :spec, __MODULE__.Spec, required: true
  end
end
