defmodule Kubernetex.Container.Probe do
  @moduledoc ~S"""
  exec
  ExecAction	One and only one of the following should be specified. Exec specifies the action to take.

  failureThreshold
  integer	Minimum consecutive failures for the probe to be considered failed after having succeeded. Defaults to 3. Minimum value is 1.

  httpGet
  HTTPGetAction	HTTPGet specifies the http request to perform.

  initialDelaySeconds
  integer	Number of seconds after the container has started before liveness probes are initiated. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes

  periodSeconds
  integer	How often (in seconds) to perform the probe. Default to 10 seconds. Minimum value is 1.

  successThreshold
  integer	Minimum consecutive successes for the probe to be considered successful after having failed. Defaults to 1. Must be 1 for liveness. Minimum value is 1.

  tcpSocket
  TCPSocketAction	TCPSocket specifies an action involving a TCP port. TCP hooks not yet supported

  timeoutSeconds
  integer	Number of seconds after which the probe times out. Defaults to 1 second. Minimum value is 1. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
  """
  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :failure_threshold, :integer, required: false, default: 3
    field :initial_delay_seconds, :integer, required: false
    field :period_seconds, :integer, required: false, default: 10
    field :success_threshold, :integer, required: false, default: 1
    field :failure_threshold, :integer, required: false, default: 3
    field :timeout_seconds, :integer, required: false, default: 1
    field :http_get, __MODULE__.HttpGetAction, required: false
  end
end
