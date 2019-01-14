defmodule Kubernetex.Service do
  @moduledoc ~S"""

  ## Fields

  ### Type
  type determines how the Service is exposed.
  Defaults to `:cluster_ip`.

  Valid options are:
   - `:external_name`
   - `:cluster_ip`
   - `:node_port`
   - `:load_balancer`

  `:external_name` maps to the specified external_name.

  `:cluster_ip` allocates a cluster-internal IP address for load-balancing to endpoints.
  Endpoints are determined by the selector or if that is not specified, by manual construction of an Endpoints object.
  If cluster_ip is `:none`, no virtual IP is allocated and the endpoints are published as a set of endpoints rather than a stable IP.

  `:node_port` builds on cluster_ip and allocates a port on every node which routes to the cluster_ip.

  `:load_balancer` builds on node_port and creates an external load-balancer (if supported in the current cloud) which routes to the cluster_ip.

  More info: https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services---service-types
  """

  @type type :: :cluster_ip | :load_balancer | :node_port | :external_name
  # defstruct type: :cluster_ip,
  #           cluster_ip: :none
  use Kubernetex.Structure

  defstructure version: "core/v1", kind: "Service" do
    field :spec, __MODULE__.Spec, required: true
    field :metadata, Kubernetex.Metadata, required: true
  end

  # Check multiple ports have a name
end
