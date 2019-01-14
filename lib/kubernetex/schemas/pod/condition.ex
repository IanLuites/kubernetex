defmodule Kubernetex.Pod.Condition do
  @moduledoc ~S"""
  Contains details for the current condition of this pod.

  ## Fields
  ### last_probe_time (`NaiveDateTime`)
  Last time the condition was probed.

  ###  last_transition_time (`NaiveDateTime`)
  Last time the condition transitioned from one status to another.

  ### message (`string`)
  Human-readable message indicating details about last transition.

  ### reason (`atom`)
  Unique, one-word, CamelCase reason for the condition's last transition.

  ### status (`boolean | :unknown`)
  Status is the status of the condition.
  Can be `true`, `false`, `:unknown`.
  More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-conditions

  ### type (`:pod_scheduled | :ready | :initialized | :unschedulable | :containers_ready`)
  Type is the type of the condition.

  The following are possible values:

  - `:pod_scheduled` the Pod has been scheduled to a node;
  - `:ready` the Pod is able to serve requests and should be added to the load balancing pools of all matching Services;
  - `:initialized` all init containers have started successfully;
  - `:unschedulable` the scheduler cannot schedule the Pod right now, for example due to lacking of resources or other constraints;
  - `:containers_ready` all containers in the Pod are ready.
  """

  alias Kubernetex.Helpers
  require Helpers

  @type status :: boolean | :unknown

  @type type :: :pod_scheduled | :ready | :initialized | :unschedulable | :containers_ready

  @type t :: %__MODULE__{
          last_probe_time: NaiveDateTime.t(),
          last_transition_time: NaiveDateTime.t(),
          message: String.t(),
          reason: atom,
          status: status,
          type: type
        }

  defstruct last_probe_time: nil,
            last_transition_time: nil,
            message: nil,
            reason: nil,
            status: :unknown,
            type: nil

  def parse(data) do
    Helpers.parse(
      __MODULE__,
      %{
        last_probe_time: Helpers.optional(&Helpers.parse_timestamp/1),
        last_transition_time: Helpers.optional(&Helpers.parse_timestamp/1),
        message:
          Helpers.optional(&if(is_binary(&1), do: {:ok, &1}, else: {:error, :invalid_message})),
        reason: Helpers.optional(&reason/1),
        status: Helpers.optional(&status/1, :unknown),
        type: &type/1
      },
      data
    )
  end

  ~w(true false unknown)a
  |> Enum.each(fn type ->
    defp status(unquote(type |> to_string |> Macro.camelize())), do: {:ok, unquote(type)}
  end)

  defp status(_), do: {:error, :invalid_condition_status}

  defp reason(reason) when is_binary(reason) do
    if reason =~ ~r/^[a-zA-Z]+$/,
      do: {:ok, reason |> Macro.underscore() |> String.to_atom()},
      else: {:error, :invalid_reason}
  end

  ~w(pod_scheduled ready initialized unschedulable containers_ready)a
  |> Enum.each(fn type ->
    defp type(unquote(type |> to_string |> Macro.camelize())), do: {:ok, unquote(type)}
  end)

  defp type(_), do: {:error, :invalid_condition_type}

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{status: status, type: type}, _opts) do
      type = type |> to_string |> Macro.camelize()

      case status do
        true -> "#Condition<#{type}>"
        false -> "#Condition<!#{type}>"
        :unknown -> "#Condition<#{type}?>"
      end
    end
  end
end
