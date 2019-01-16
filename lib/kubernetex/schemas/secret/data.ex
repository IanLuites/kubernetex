defmodule Kubernetex.Secret.Data do
  def parse(data) when is_map(data) do
    MapX.new(data, fn {k, v} ->
      with {:ok, v} <- Base.decode64(v, padding: true, case: :upper), do: {:ok, k, v}
    end)
  end

  def parse(_), do: {:error, :invalid_secret_data}

  def dump(data) do
    MapX.new(
      data,
      fn {k, v} -> {:ok, k, Base.encode64(v, padding: true, case: :upper)} end
    )
  end
end
