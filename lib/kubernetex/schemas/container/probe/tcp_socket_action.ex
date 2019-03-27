defmodule Kubernetex.Container.Probe.TCPSocketAction do
  @moduledoc ~S"""
  host
  string	Host name to connect to, defaults to the pod IP. You probably want to set "Host" in httpHeaders instead.

  port
  Name or number of the port to access on the container. Number must be in the range 1 to 65535. Name must be an IANA_SVC_NAME.
  """
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :host, :string, required: false
    field :port, :integer, required: true
  end
end
