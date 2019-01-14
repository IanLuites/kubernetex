defmodule Kubernetex.Ingress.Spec do
  @moduledoc ~S"""

  """
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :backend, Kubernetex.Ingress.Backend, required: false
    field :rules, {:array, Kubernetex.Ingress.Rule}, required: false, default: []
  end

  def validate(spec = %{backend: backend, rules: rules}) do
    cond do
      is_nil(backend) and rules == [] -> {:error, :missing_backend_and_rules}
      is_nil(backend) -> {:ok, spec}
      rules == [] -> {:ok, spec}
      :conflict -> {:error, :conflicting_backend_and_rules}
    end
  end
end
