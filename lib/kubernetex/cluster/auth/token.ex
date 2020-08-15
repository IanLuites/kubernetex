defmodule Kubernetex.Cluster.Auth.Token do
  @moduledoc ~S"""
  Kubernetes token based authentication.
  """

  @typedoc @moduledoc
  @type t :: %__MODULE__{
          user: String.t() | nil,
          token: binary
        }
  defstruct [
    :user,
    :token
  ]

  @doc "Parse #{@moduledoc}"
  @spec parse(any) :: {:ok, t} | {:error, atom}
  def parse(%{user: %{token: t}, name: name}) when is_binary(t) do
    {:ok, %__MODULE__{user: name, token: t}}
  end

  def parse(_), do: {:error, :invalid_token_auth}

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{user: user}, _opts), do: "#TokenAuth<#{user}>"
  end
end
