defmodule Kubernetex.Replicas do
  @type t :: %__MODULE__{replicas: pos_integer}

  defstruct [
    :replicas
  ]

  def dump(%__MODULE__{replicas: replicas}), do: {:ok, replicas}

  @spec parse!(any) :: t | no_return
  def parse!(value) do
    case parse(value) do
      {:ok, replicas} -> replicas
      {:error, reason} -> raise "Invalid replica value: #{reason}"
    end
  end

  @spec parse(any) :: {:ok, t} | {:error, atom}
  def parse(replicas = %__MODULE__{}), do: {:ok, replicas}

  def parse(value) when is_number(value) do
    value = trunc(value)
    if value > 0, do: {:ok, %__MODULE__{replicas: value}}, else: {:error, :invalid_replica_range}
  end

  def parse(value) when is_binary(value) do
    case Float.parse(value) do
      {replicas, ""} -> parse(replicas)
      _ -> {:error, :invalid_replica_value}
    end
  end

  def parse(_), do: {:error, :invalid_replica_value}

  defimpl Inspect, for: __MODULE__ do
    import Inspect.Algebra

    def inspect(%{replicas: replicas}, _opts) do
      concat(["#Replicas<", to_string(replicas), ">"])
    end
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(%{replicas: replicas}, _opts), do: Jason.Encode.integer(replicas)
  end
end
