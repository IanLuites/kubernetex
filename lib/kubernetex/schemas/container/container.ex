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
    field :env, {:array, __MODULE__.EnvVar}, required: false, default: []
    field :env_from, {:array, __MODULE__.EnvFromSource}, required: false, default: []
    field :resources, __MODULE__.Resources, required: false, default: nil
    field :liveness_probe, __MODULE__.Probe, required: false
    field :readiness_probe, __MODULE__.Probe, required: false
  end
end
