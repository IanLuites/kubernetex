defmodule Kubernetex.Helpers do
  @moduledoc false

  defmacro optional(parse, default \\ nil) do
    quote do
      fn
        nil -> {:ok, unquote(default)}
        input -> unquote(parse).(input)
      end
    end
  end

  defmacro many(parse) do
    quote do
      fn input -> EnumX.map(input, unquote(parse)) end
    end
  end

  defmacro enum(options, default \\ {:error, :invalid_enum}) do
    lookup =
      options
      |> Macro.expand(__CALLER__)
      |> Enum.flat_map(&[{&1, &1}, {to_string(&1), &1}, {Macro.camelize(to_string(&1)), &1}])
      |> Map.new(fn {k, v} -> {k, {:ok, v}} end)

    quote do
      fn input -> unquote(Macro.escape(lookup))[input] || unquote(default) end
    end
  end

  @spec snakize(atom | String.t()) :: atom | String.t()
  defp snakize(h) when is_atom(h), do: String.to_atom(snakize(to_string(h)))
  defp snakize(data), do: do_snakize(Regex.replace(~r/(^|_)ip(_|$)/, data, "\\1IP\\2"))

  defp do_snakize(<<h, t::binary>>), do: <<h>> <> do_camelize(t)

  defp do_camelize(<<?_, ?_, t::binary>>), do: do_camelize(<<?_, t::binary>>)

  defp do_camelize(<<?_, h, t::binary>>) when h >= ?a and h <= ?z,
    do: <<h - 32>> <> do_camelize(t)

  defp do_camelize(<<?_>>), do: <<>>
  defp do_camelize(<<?_, t::binary>>), do: do_camelize(t)
  defp do_camelize(<<h, t::binary>>), do: <<h>> <> do_camelize(t)
  defp do_camelize(<<>>), do: <<>>

  @type protocol :: :tcp | :udp | :sctp

  @type port_number :: 1..65535

  @spec parse(module, %{atom => fun}, map) :: {:ok, %{}} | {:error, term}
  def parse(type, fields, data) do
    with {:ok, parsed} <-
           MapX.new(fields, fn {field, parser} ->
             v = MapX.get(data, field) || MapX.get(data, snakize(field))
             with {:ok, d} <- parser.(v), do: {:ok, field, d}
           end) do
      {:ok, struct!(type, parsed)}
    end
  end

  @spec parse_protocol(any) :: {:ok, protocol} | {:error, :unsupported_protocol}
  def parse_protocol(nil), do: {:ok, :tcp}
  def parse_protocol(value) when value in ~w(tcp udp sctp)a, do: {:ok, value}

  def parse_protocol(value) do
    value = String.downcase(value)

    if value in ~W(tcp udp sctp),
      do: {:ok, String.to_existing_atom(value)},
      else: {:error, :unsupported_protocol}
  end

  @spec parse_port(any) :: {:ok, port} | {:error, :invalid_port}
  def parse_port(value) when value in 1..65535, do: {:ok, value}

  def parse_port(value) when is_binary(value) do
    case Integer.parse(value) do
      {port, _} -> parse_port(port)
      :error -> {:error, :invalid_port}
    end
  end

  def parse_port(_), do: {:error, :invalid_port}

  def parse_timestamp(timestamp), do: NaiveDateTime.from_iso8601(timestamp)

  def parse_message(message) when is_binary(message), do: {:ok, message}
  def parse_message(_), do: {:error, :invalid_message}

  def reason(reason) when is_binary(reason) do
    if reason =~ ~r/^[a-zA-Z]+$/,
      do: {:ok, reason |> Macro.underscore() |> String.to_atom()},
      else: {:error, :invalid_reason}
  end

  def reason(reason) when is_atom(reason), do: {:ok, reason}

  def reason(_), do: {:error, :invalid_reason}

  @doc ~S"""
  C_IDENTIFIER

  This is a string that conforms to the definition of an "identifier"
     in the C language.  This is captured by the following regex:
         `[A-Za-z_][A-Za-z0-9_]*`

     This defines the format, but not the length restriction, which should be
     specified at the definition of any field of this type.
  """
  def parse_c_identifier(data) when is_binary(data) do
    if data =~ ~r/^[A-Za-z_][A-Za-z0-9_]*$/,
      do: {:ok, data},
      else: {:error, :invalid_c_identifier}
  end

  def parse_c_identifier(_), do: {:error, :invalid_c_identifier}

  @doc ~S"""
  DNS_LABEL

  This is a string, no more than 63 characters long, that conforms
  to the definition of a "label" in RFCs 1035 and 1123.  This is captured
  by the following regex:
  `[a-z0-9]([-a-z0-9]*[a-z0-9])?`
  """
  def parse_dns_label(data) when is_binary(data) do
    if String.length(data) < 64 and data =~ ~r/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/,
      do: {:ok, data},
      else: {:error, :invalid_dns_label}
  end

  def parse_dns_label(_), do: {:error, :invalid_dns_label}

  @doc ~S"""
  DNS_SUBDOMAIN

  This is a string, no more than 253 characters long, that conforms
  to the definition of a "subdomain" in RFCs 1035 and 1123.  This is captured
  by the following regex:
  `[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*`
  or more simply:
  DNS_LABEL(\.DNS_LABEL)*
  """
  def parse_dns_subdomain(data) when is_binary(data) do
    if String.length(data) < 254 and
         data =~ ~r/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/,
       do: {:ok, data},
       else: {:error, :invalid_dns_subdomain}
  end

  def parse_dns_subdomain(_), do: {:error, :invalid_dns_subdomain}

  @doc ~S"""
  IANA_SVC_NAME

  This is a string, no more than 15 characters long, that
  conforms to the definition of IANA service name in RFC 6335.
  It must contains at least one letter [a-z] and it must contains only [a-z0-9-].
  Hypens ('-') cannot be leading or trailing character of the string
  and cannot be adjacent to other hyphens.
  """
  def parse_iana_svc_name(data) when is_binary(data) do
    if String.length(data) < 16 and data =~ ~r/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/ and
         data =~ ~r/[a-z]/,
       do: {:ok, data},
       else: {:error, :invalid_iana_svc_name}
  end

  def parse_iana_svc_name(_), do: {:error, :invalid_iana_svc_name}

  def target_port(value) do
    case parse_port(value) do
      {:ok, port} -> {:ok, port}
      {:error, _} -> parse_iana_svc_name(value)
    end
  end

  @ip_type %{
    4 => :ipv4,
    8 => :ipv6
  }

  def parse_ip(value) when is_binary(value), do: parse_ip(String.to_charlist(value))

  def parse_ip(value) do
    with {:ok, ip} <- :inet.parse_address(value) do
      {:ok, %Kubernetex.IP{ip: ip, type: @ip_type[tuple_size(ip)]}}
    end
  end
end
