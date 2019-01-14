defmodule Kubernetex.Service.Spec do
  @moduledoc ~S"""

  """
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :type, {:enum, ~w(cluster_ip load_balancer node_port external_name)a},
      required: false,
      default: :cluster_ip

    field :cluster_ip, :ip, required: false
    field :selector, :map, required: true, default: %{}
    field :ports, {:array, Kubernetex.Service.Port}, required: true
  end

  def validate(spec = %__MODULE__{ports: ports}) do
    cond do
      Enum.count(ports) <= 1 -> {:ok, spec}
      Enum.all?(ports, &(&1.name != nil)) -> {:ok, spec}
      :ports_require_name -> {:error, :multiple_ports_require_names}
    end
  end
end
