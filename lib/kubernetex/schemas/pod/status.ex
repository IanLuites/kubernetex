defmodule Kubernetex.Pod.Status do
  @moduledoc ~S"""
  ## Fields

  ### conditions (`[Kubernetex.Pod.Condition]`)
  Current service state of pod.
  See: `Kubernetex.Pod.Condition`.

  ### container_statuses (`[Kubernetex.Container.Status]`)
  The list has one entry per container in the manifest.
  Each entry is currently the output of `docker inspect`.
  See: `Kubernetex.Container.Status`.

  ### host_ip (`Kubernetex.IP`)
  IP address of the host to which the pod is assigned.
  Empty if not yet scheduled.

  ### init_container_statuses
  The list has one entry per init container in the manifest.
  The most recent successful init container will have ready = true, the most recently started container will have `start_time` set.
  See: `Kubernetex.Container.Status`.

  ### message (`string`)
  A human readable message indicating details about why the pod is in this condition.

  ### nominated_node_name (`string`)
  `nominated_node_name` is set only when this pod preempts other pods on the node,
  but it cannot be scheduled right away as preemption victims receive their graceful termination periods.
  This field does not guarantee that the pod will be scheduled on this node.
  Scheduler may decide to place the pod elsewhere if other nodes become available sooner.
  Scheduler may also decide to give the resources on this node to a higher priority pod that is created after preemption.
  As a result, this field may be different than `Kuberntex.Pod.node_name` when the pod is scheduled.

  ### phase (`:pending | :running | :succeeded | :failed | :unknown`)
  The phase of a Pod is a simple, high-level summary of where the Pod is in its lifecycle.
  The conditions array, the reason and message fields, and the individual container status arrays contain more detail about the pod's status.
  There are five possible phase values:

  - `:pending` The pod has been accepted by the Kubernetes system, but one or more of the container images has not been created. This includes time before being scheduled as well as time spent downloading images over the network, which could take a while.
  - `:running` The pod has been bound to a node, and all of the containers have been created. At least one container is still running, or is in the process of starting or restarting.
  - `:succeeded` All containers in the pod have terminated in success, and will not be restarted.
  - `:failed` All containers in the pod have terminated, and at least one container has terminated in failure. The container either exited with non-zero status or was terminated by the system.
  - `:unknown` For some reason the state of the pod could not be obtained, typically due to an error in communicating with the host of the pod.

  More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-phase

  ###  pod_ip (`Kubernetex.IP`)
  IP address allocated to the pod.
  Routable at least within the cluster.
  Empty if not yet allocated.

  ### qos_class (`:guaranteed | :burstable | :best_effort)
  The Quality of Service (QOS) classification assigned to the pod based on resource requirements.

  The QoS can be on of the following values:

  - `:guaranteed` If `limits` and optionally `requests` (not equal to 0) are set for all resources across all containers and they are equal, then the pod is classified as `:guaranteed`.
  - `:burstable` If `requests` and optionally `limits` are set (not equal to 0) for one or more resources across one or more containers, and they are not equal, then the pod is classified as `:burstable`. When limits are not specified, they default to the node capacity.
  - `:best_effort` If `requests` and `limits` are not set for all of the resources, across all containers, then the pod is classified as `:best_effort`.

  For more info see: https://github.com/kubernetes/community/blob/master/contributors/design-proposals/node/resource-qos.md

  ### reason (`atom`)
  A brief message indicating details about why the pod is in this state. e.g. `:evicted`.

  ### start_time (`NaiveDateTime`)
  RFC 3339 date and time at which the object was acknowledged by the Kubelet.
  This is before the Kubelet pulled the container image(s) for the pod.
  """

  @type phase :: :pending | :running | :succeeded | :failed | :unknown
  @type qos_class :: :guaranteed | :burstable | :best_effort

  @phase ~w(pending running succeeded failed unknown)a
  @qos ~w(guaranteed burstable best_effort)a

  # @type t :: %__MODULE__{
  #         conditions: [Kubernetex.Pod.Condition.t()],
  #         container_statuses: [Kubernetex.Container.Status.t()],
  #         init_container_statuses: [Kubernetex.Container.Status.t()],
  #         message: String.t(),
  #         nominated_node_name: String.t(),
  #         phase: phase,
  #         host_ip: Kubernetex.IP.t(),
  #         qos_class: qos_class,
  #         reason: atom,
  #         start_time: NaiveDateTime.t()
  #       }

  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :conditions, {:array, Kubernetex.Pod.Condition}, required: false, default: []
    field :container_statuses, {:array, Kubernetex.Container.Status}, required: false, default: []

    field :init_container_statuses, {:array, Kubernetex.Container.Status},
      required: false,
      default: []

    field :message, :message, required: false, default: nil
    field :nominated_node_name, :string, required: false
    field :phase, {:enum, @phase}, required: true
    field :host, :ip, required: false, default: nil
    field :qos_class, {:enum, @qos}, required: true
    field :reason, :reason, required: false, default: nil
    field :start_time, :timestamp, required: false, default: nil
  end
end
