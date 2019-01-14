defmodule Kubernetex.Service.Port do
  @moduledoc ~S"""
  ## Fields

  ### name (`string`)
  The name of this port within the service.
  his must be a DNS_LABEL.
  All ports within a ServiceSpec must have unique names.
  This maps to the 'Name' field in EndpointPort objects.
  Optional if only one `Service.Port` is defined on this service.

  ### node_port (`integer`)
  The port on each node on which this service is exposed when `type: :node_port` or `:load_balancer`.
  Usually assigned by the system.
  If specified, it will be allocated to the service if unused or else creation of the service will fail.
  Default is to auto-allocate a port if the ServiceType of this Service requires one.

  More info: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport

  ### port (`integer`)
  The port that will be exposed by this service.

  ### protocol (`:tcp | :udp | :sctp`)
  The IP protocol for this port.
  Supports `:tcp`, `:udp`, and :`sctp`.
  Default is `:tcp`.

  ### target_port (`integer | string`)
  Number or name of the port to access on the pods targeted by the service.
  Number must be in the range 1 to 65535.
  Name must be an IANA_SVC_NAME.
  If this is a string, it will be looked up as a named port in the target Pod's container ports.
  If this is not specified, the value of the `port` field is used (an identity map).
  This field is ignored for services with `cluster_ip: :none`,
  and should be omitted or set equal to the `port` field.

  More info: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service
  """

  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :name, :dns_label, required: false
    field :node_port, :port, required: false
    field :port, :port, required: true
    field :protocol, :protocol, required: false, default: :tcp
    field :target_port, {:either, :port, :iana_svc_name}, required: false
  end

  # alias Kubernetex.Helpers
  # require Helpers

  # @type t :: %__MODULE__{
  #         name: String.t(),
  #         protocol: Kubernetex.Helpers.protocol(),
  #         node_port: Kubernetex.Helpers.port_number() | nil,
  #         port: Kubernetex.Helpers.port_number(),
  #         target_port: Kubernetex.Helpers.port_number() | String.t()
  #       }

  # defstruct name: nil,
  #           protocol: :tcp,
  #           port: nil,
  #           target_port: nil,
  #           node_port: nil

  # def parse(data) do
  #   Helpers.parse(
  #     __MODULE__,
  #     %{
  #       name: Helpers.optional(&Helpers.parse_dns_label/1),
  #       protocol: Helpers.optional(&Helpers.parse_protocol/1, :tcp),
  #       port: &Helpers.parse_port/1,
  #       target_port: Helpers.optional(&Helpers.target_port/1),
  #       node_port: Helpers.optional(&Helpers.parse_port/1)
  #     },
  #     data
  #   )
  # end
end
