defmodule Kubernetex.Primitives.Message do
  alias Kubernetex.Primitives.String, as: Str

  @spec parse(any) :: {:ok, String.t()} | {:error, :invalid_message}
  def parse(message) do
    with {:error, _} <- Str.parse(message), do: {:error, :invalid_message}
  end

  def dump(string, _opts \\ []), do: {:ok, string}
end

defmodule Kubernetex.Primitives.Reason do
  @spec parse(any) :: {:ok, String.t()} | {:error, :invalid_reason}
  def parse(reason) when is_binary(reason) do
    if reason =~ ~r/^[a-zA-Z]+$/,
      do: {:ok, reason |> Macro.underscore() |> String.to_atom()},
      else: {:error, :invalid_reason}
  end

  def parse(_), do: {:error, :invalid_reason}

  def dump(reason, _opts \\ []), do: {:ok, to_string(reason)}
end

defmodule Kubernetex.Primitives.CIndentifier do
  @moduledoc ~S"""
  C_IDENTIFIER

  This is a string that conforms to the definition of an "identifier"
     in the C language.  This is captured by the following regex:
         `[A-Za-z_][A-Za-z0-9_]*`

     This defines the format, but not the length restriction, which should be
     specified at the definition of any field of this type.
  """

  @doc @moduledoc
  def parse(data) when is_binary(data) do
    if data =~ ~r/^[A-Za-z_][A-Za-z0-9_]*$/,
      do: {:ok, data},
      else: {:error, :invalid_c_identifier}
  end

  def parse(_), do: {:error, :invalid_c_identifier}

  def dump(identifier, _opts \\ []), do: {:ok, identifier}
end

defmodule Kubernetex.Primitives.DNSLabel do
  @moduledoc ~S"""
  DNS_LABEL

  This is a string, no more than 63 characters long, that conforms
  to the definition of a "label" in RFCs 1035 and 1123.  This is captured
  by the following regex:
  `[a-z0-9]([-a-z0-9]*[a-z0-9])?`
  """
  @doc @moduledoc
  def parse(data) when is_binary(data) do
    if String.length(data) < 64 and data =~ ~r/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/,
      do: {:ok, data},
      else: {:error, :invalid_dns_label}
  end

  def parse(_), do: {:error, :invalid_dns_label}
  def dump(label, _opts \\ []), do: {:ok, label}
end

defmodule Kubernetex.Primitives.DNSSubdomain do
  @moduledoc ~S"""
  DNS_SUBDOMAIN

  This is a string, no more than 253 characters long, that conforms
  to the definition of a "subdomain" in RFCs 1035 and 1123.  This is captured
  by the following regex:
  `[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*`
  or more simply:
  DNS_LABEL(\.DNS_LABEL)*
  """
  @doc @moduledoc
  def parse(data) when is_binary(data) do
    if String.length(data) < 254 and
         data =~ ~r/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/,
       do: {:ok, data},
       else: {:error, :invalid_dns_subdomain}
  end

  def parse(_), do: {:error, :invalid_dns_subdomain}
  def dump(domain, _opts \\ []), do: {:ok, domain}
end

defmodule Kubernetex.Primitives.IANASvcName do
  @moduledoc ~S"""
  IANA_SVC_NAME

  This is a string, no more than 15 characters long, that
  conforms to the definition of IANA service name in RFC 6335.
  It must contains at least one letter [a-z] and it must contains only [a-z0-9-].
  Hypens ('-') cannot be leading or trailing character of the string
  and cannot be adjacent to other hyphens.
  """
  @doc @moduledoc
  def parse(data) when is_binary(data) do
    if String.length(data) < 16 and data =~ ~r/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/ and
         data =~ ~r/[a-z]/,
       do: {:ok, data},
       else: {:error, :invalid_iana_svc_name}
  end

  def parse(_), do: {:error, :invalid_iana_svc_name}

  def dump(name, _opts \\ []), do: {:ok, name}
end
