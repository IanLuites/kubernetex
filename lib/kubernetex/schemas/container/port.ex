defmodule Kubernetex.Container.Port do
  @moduledoc ~S"""
  ## Fields
  ### container_port (`integer`)
  Number of port to expose on the pod's IP address.
  This must be a valid port number, 0 < x < 65536.

  ### host_ip (`string`)
  What host IP to bind the external port to.

  ### host_port (`integer`)
  Number of port to expose on the host.
  If specified, this must be a valid port number, 0 < x < 65536.
  If HostNetwork is specified, this must match `Container.Port`.
  Most containers do not need this.

  ### name (`string`)
  If specified, this must be an IANA_SVC_NAME and unique within the pod.
  Each named port in a pod must have a unique name.
  Name for the port that can be referred to by services.

  ### protocol (`:tcp | :udp | :sctp`)
  Protocol for port.
  Must be `:udp`, `:tcp`, or `:sctp`.
  Defaults to ``tcp`.
  """
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :container_port, :port, required: true
    field :host_ip, :ip, required: false
    field :host_port, :port, required: false
    field :protocol, :protocol, required: false, default: :tcp
  end

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{container_port: container, host_port: host}, _opts) do
      if host, do: "#Port<#{host}:#{container}>", else: "#Port<#{container}>"
    end
  end
end
