defmodule Kubernetex.Memory do
  @units_1000 ~w(E P T G M K)a
  @units_1024 ~w(Ei Pi Ti Gi Mi Ki)a
  @units @units_1000 ++ @units_1024
  @units_table Map.new(@units, &{String.downcase(to_string(&1)), &1})

  @type t :: %__MODULE__{}
  defstruct [
    :memory,
    unit: :Mi
  ]

  def dump(%__MODULE__{memory: memory, unit: unit}, _opts \\ []), do: {:ok, "#{memory}#{unit}"}

  @spec parse!(any) :: t | no_return
  def parse!(value) do
    case parse(value) do
      {:ok, memory} -> memory
      {:error, reason} -> raise "Invalid Memory value: #{reason}"
    end
  end

  @spec parse(any) :: {:ok, t} | {:error, atom}
  def parse(value = %__MODULE__{}), do: {:ok, value}

  def parse(value) when is_binary(value) do
    with {memory, unit_string} when memory > 0 <- Float.parse(value),
         unit when unit != nil <- @units_table[String.downcase(unit_string)] do
      cond do
        not String.contains?(value, ".") ->
          {:ok, %__MODULE__{memory: trunc(memory), unit: unit}}

        Float.floor(memory) == memory ->
          {:ok, %__MODULE__{memory: trunc(memory), unit: unit}}

        :down_value ->
          down = unit_down(memory, unit)
          if down.memory > 0, do: {:ok, down}, else: {:error, :invalid_memory_range}
      end
    else
      :error -> {:error, :invalid_memory_format}
      {_, _} -> {:error, :invalid_memory_range}
      nil -> {:error, :invalid_memory_unit}
    end
  end

  def parse(value) when is_number(value), do: {:error, :missing_memory_unit}
  def parse(_), do: {:error, :invalid_memory_format}

  defp unit_down(value, unit)
  defp unit_down(value, :K), do: %__MODULE__{memory: trunc(value), unit: :K}
  defp unit_down(value, :Ki), do: %__MODULE__{memory: trunc(value), unit: :Ki}

  Enum.each(
    Enum.zip(@units_1000, @units_1000 -- [:E]),
    fn {u, u_down} ->
      defp unit_down(value, unquote(u)),
        do: %__MODULE__{memory: trunc(value * 1000), unit: unquote(u_down)}
    end
  )

  Enum.each(
    Enum.zip(@units_1024, @units_1024 -- [:Ei]),
    fn {u, u_down} ->
      defp unit_down(value, unquote(u)),
        do: %__MODULE__{memory: trunc(value * 1024), unit: unquote(u_down)}
    end
  )

  defimpl Inspect, for: __MODULE__ do
    import Inspect.Algebra

    def inspect(%{memory: memory, unit: unit}, _opts) do
      concat(["#Memory<", to_string(memory), to_string(unit), ">"])
    end
  end

  defimpl Jason.Encoder, for: __MODULE__ do
    def encode(%{memory: memory, unit: unit}, _opts),
      do: [?", to_string(memory), to_string(unit), ?"]
  end
end
