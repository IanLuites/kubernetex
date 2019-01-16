defmodule Kubernetex.Container.EnvFromSource do
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :prefix, :string, required: false
    field :secret_ref, Kubernetex.SecretEnvSource, required: false
    field :config_map_ref, Kubernetex.ConfigMapEnvSource, required: false
  end

  def validate(data) do
    secret = not is_nil(data.secret_ref)
    config = not is_nil(data.config_map_ref)

    cond do
      secret and config -> {:error, :can_not_have_both_secret_and_config_ref}
      secret or config -> {:ok, data}
      not (secret or config) -> {:error, :need_either_secret_or_config_ref}
    end
  end
end
