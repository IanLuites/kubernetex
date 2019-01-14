defmodule Kubernetex.Primitives.Protocol do
  @type t :: :tcp | :udp | :sctp

  @doc ~S"""
  Parse protocol.
  """
  @spec parse(any) :: {:ok, t} | {:error, :unsupported_protocol}
  def parse(nil), do: {:ok, :tcp}
  def parse(value) when value in ~w(tcp udp sctp)a, do: {:ok, value}

  def parse(value) do
    value = String.downcase(value)

    if value in ~W(tcp udp sctp),
      do: {:ok, String.to_existing_atom(value)},
      else: {:error, :unsupported_protocol}
  end

  def dump(protocol), do: {:ok, protocol |> to_string |> String.upcase()}
end

defmodule Kubernetex.Primitives.Port do
  @type t :: 1..65535

  @doc ~S"""
  Parse port.
  """
  @spec parse(any) :: {:ok, t} | {:error, :invalid_port}
  def parse(value) when value in 1..65535, do: {:ok, value}

  def parse(value) when is_binary(value) do
    case Integer.parse(value) do
      {port, _} -> parse(port)
      :error -> {:error, :invalid_port}
    end
  end

  def parse(_), do: {:error, :invalid_port}

  def dump(port), do: {:ok, port}
end

defmodule Kubernetex.Primitives.IP do
  @ip_type %{
    4 => :ipv4,
    8 => :ipv6
  }

  def parse(value) when is_binary(value), do: parse(String.to_charlist(value))

  def parse(value) do
    with {:ok, ip} <- :inet.parse_address(value) do
      {:ok, %Kubernetex.IP{ip: ip, type: @ip_type[tuple_size(ip)]}}
    end
  end

  def dump(%{ip: ip}) do
    {:ok, ip |> :inet.ntoa() |> to_string}
  end
end
