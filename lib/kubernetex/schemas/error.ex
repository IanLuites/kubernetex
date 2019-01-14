defmodule Kubernetex.Error do
  defstruct [
    :api_version,
    :code,
    :details,
    :message,
    :kind,
    :metadata,
    :reason,
    :status
  ]

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{reason: reason}, _opts), do: "#Error<#{reason}>"
  end
end
