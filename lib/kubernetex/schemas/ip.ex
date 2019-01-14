defmodule Kubernetex.IP do
  @type type :: :ipv4 | :ipv6

  @type t :: %__MODULE__{ip: tuple, type: type}

  defstruct [:ip, :type]

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{ip: ip, type: type}, _opts) do
      ip = :inet_parse.ntoa(ip)

      case type do
        :ipv4 -> "#IPv4<#{ip}>"
        :ipv6 -> "#IPv6<#{ip}>"
      end
    end
  end
end
