defmodule Kubernetex.Primitives.Map do
  @spec parse(any) :: {:ok, map} | {:error, :invalid_map}
  def parse(data) when is_map(data), do: {:ok, data}
  def parse(_), do: {:error, :invalid_map}

  def dump(data), do: {:ok, data}
end

defmodule Kubernetex.Primitives.Timestamp do
  @spec parse(any) :: {:ok, NaiveDateTime.t()} | {:error, :invalid_timestamp}
  def parse(timestamp) when is_binary(timestamp) do
    with {:error, _} <- NaiveDateTime.from_iso8601(timestamp), do: {:error, :invalid_timestamp}
  end

  def parse(nil), do: {:ok, nil}
  def parse(_), do: {:error, :invalid_timestamp}

  def dump(data), do: {:ok, NaiveDateTime.to_iso8601(data) <> "Z"}
end

defmodule Kubernetex.Primitives.String do
  @spec parse(any) :: {:ok, String.t()} | {:error, :invalid_string}
  def parse(binary) when is_binary(binary) do
    if String.printable?(binary), do: {:ok, binary}, else: {:error, :invalid_string}
  end

  def parse(_), do: {:error, :invalid_string}

  def dump(data), do: {:ok, data}
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
  def dump(data), do: {:ok, data}
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
  def dump(data), do: {:ok, data}
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
  def dump(data), do: {:ok, data}
end
