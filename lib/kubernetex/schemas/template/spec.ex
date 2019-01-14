defmodule Kubernetex.Template.Spec do
  use Kubernetex.Structure

  #   spec:
  #     containers:
  #     - name: nginx
  #       image: nginx:1.7.9
  #       ports:
  #       - containerPort: 80

  defstructure version: "core/v1" do
    field :containers, {:array, Kubernetex.Container}, required: true
  end
end
