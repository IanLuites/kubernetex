defmodule Kubernetex.CPU do
  @type t :: %__MODULE__{}

  defstruct [
    :cpu,
    unit: :m
  ]

  def dump(%__MODULE__{cpu: cpu}, _opts \\ []), do: {:ok, "#{cpu}m"}

  @spec parse!(any) :: t | no_return
  def parse!(value) do
    case parse(value) do
      {:ok, cpu} -> cpu
      {:error, reason} -> raise "Invalid CPU value: #{reason}"
    end
  end

  @spec parse(any) :: {:ok, t} | {:error, atom}
  def parse(value = %__MODULE__{}), do: {:ok, value}

  def parse(value) when is_integer(value) do
    if value > 0, do: {:ok, %__MODULE__{cpu: value * 1000}}, else: {:error, :invalid_cpu_range}
  end

  def parse(value) when is_float(value) do
    v = trunc(value * 1000)

    if v > 0, do: {:ok, %__MODULE__{cpu: v}}, else: {:error, :invalid_cpu_range}
  end

  def parse(value) when is_binary(value) do
    if String.contains?(value, ".") do
      case Float.parse(value) do
        {cpu, _} when cpu <= 0 -> {:error, :invalid_cpu_range}
        {cpu, ""} -> parse(cpu)
        {cpu, "m"} -> {:ok, %__MODULE__{cpu: trunc(cpu)}}
        {_, _} -> {:error, :invalid_cpu_range}
        :error -> {:error, :invalid_cpu_value}
      end
    else
      case Integer.parse(value) do
        {cpu, _} when cpu <= 0 -> {:error, :invalid_cpu_range}
        {cpu, ""} -> parse(cpu)
        {cpu, "m"} -> {:ok, %__MODULE__{cpu: cpu}}
        {_, _} -> {:error, :invalid_cpu_range}
        :error -> {:error, :invalid_cpu_value}
      end
    end
  end

  defimpl Inspect, for: __MODULE__ do
    import Inspect.Algebra

    def inspect(%{cpu: cpu}, _opts) do
      if rem(cpu, 1_000) == 0 do
        concat(["#CPU<", to_string(Integer.floor_div(cpu, 1_000)), ">"])
      else
        concat(["#CPU<", to_string(cpu), "m>"])
      end
    end
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(%{cpu: cpu}, _opts) do
      if rem(cpu, 1_000) == 0 do
        [?", to_string(Integer.floor_div(cpu, 1_000)), ?"]
      else
        [?", to_string(cpu), "m\""]
      end
    end
  end
end
