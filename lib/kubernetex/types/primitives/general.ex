defmodule Kubernetex.Primitives.Map do
  @spec parse(any) :: {:ok, map} | {:error, :invalid_map}
  def parse(data) when is_map(data), do: {:ok, data}
  def parse(_), do: {:error, :invalid_map}

  def dump(data, _opts \\ []), do: {:ok, data}
end

defmodule Kubernetex.Primitives.Timestamp do
  @spec parse(any) :: {:ok, NaiveDateTime.t()} | {:error, :invalid_timestamp}
  def parse(timestamp) when is_binary(timestamp) do
    with {:error, _} <- NaiveDateTime.from_iso8601(timestamp), do: {:error, :invalid_timestamp}
  end

  def parse(nil), do: {:ok, nil}
  def parse(_), do: {:error, :invalid_timestamp}

  def dump(data, _opts \\ []), do: {:ok, NaiveDateTime.to_iso8601(data) <> "Z"}
end

defmodule Kubernetex.Primitives.String do
  @spec parse(any) :: {:ok, String.t()} | {:error, :invalid_string}
  def parse(binary) when is_binary(binary) do
    if String.printable?(binary), do: {:ok, binary}, else: {:error, :invalid_string}
  end

  def parse(_), do: {:error, :invalid_string}

  def dump(data, _opts \\ []), do: {:ok, data}
end

defmodule Kubernetex.Primitives.Boolean do
  def parse(true), do: {:ok, true}
  def parse(false), do: {:ok, false}

  def parse(binary) when is_binary(binary) do
    binary = String.downcase(binary)

    cond do
      binary in ["true", "1"] -> {:ok, true}
      binary in ["false", "0"] -> {:ok, false}
      :error -> {:error, :invalid_boolean}
    end
  end

  def parse(_), do: {:error, :invalid_boolean}
  def dump(data, _opts \\ []), do: {:ok, data}
end

defmodule Kubernetex.Primitives.Integer do
  def parse(number) when is_integer(number) do
    {:ok, number}
  end

  def parse(number) when is_binary(number) do
    case Integer.parse(number) do
      {number, ""} -> parse(number)
      _ -> {:error, :invalid_integer}
    end
  end

  def parse(_), do: {:error, :invalid_integer}
  def dump(data, _opts \\ []), do: {:ok, data}
end

defmodule Kubernetex.Primitives.NonNegativeInteger do
  def parse(number) when is_integer(number) and number >= 0 do
    {:ok, number}
  end

  def parse(number) when is_binary(number) do
    case Integer.parse(number) do
      {number, ""} -> parse(number)
      _ -> {:error, :invalid_non_neg_integer}
    end
  end

  def parse(_), do: {:error, :invalid_non_neg_integer}
  def dump(data, _opts \\ []), do: {:ok, data}
end

defmodule Kubernetex.Primitives.Status do
  @status ~w(true false unknown)a

  Enum.each(@status, fn type ->
    def parse(unquote(type |> to_string |> Macro.camelize())), do: {:ok, unquote(type)}
  end)

  Enum.each(@status, fn type ->
    def parse(unquote(type |> to_string)), do: {:ok, unquote(type)}
  end)

  Enum.each(@status, fn type ->
    def parse(unquote(type)), do: {:ok, unquote(type)}
  end)

  def parse(_), do: {:error, :invalid_status}
  def dump(data, _opts \\ []), do: {:ok, data |> to_string() |> Macro.camelize()}
end

defmodule Kubernetex.Primitives.ConditionType do
  @types ~w(available progressing pod_scheduled ready initialized unschedulable containers_ready)a

  Enum.each(@types, fn type ->
    def parse(unquote(type |> to_string |> Macro.camelize())), do: {:ok, unquote(type)}
  end)

  Enum.each(@types, fn type ->
    def parse(unquote(type |> to_string)), do: {:ok, unquote(type)}
  end)

  Enum.each(@types, fn type ->
    def parse(unquote(type)), do: {:ok, unquote(type)}
  end)

  def parse(e) do
    IO.inspect(e)
    {:error, :invalid_condition_type}
  end

  def dump(data, _opts \\ []), do: {:ok, data |> to_string() |> Macro.camelize()}
end
