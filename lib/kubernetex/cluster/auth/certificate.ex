defmodule Kubernetex.Cluster.Auth.Certificate do
  @moduledoc ~S"""
  Kubernetes certificate based authentication.
  """

  @typedoc @moduledoc
  @type t :: %__MODULE__{
          user: String.t() | nil,
          key: binary,
          cert: binary
        }
  defstruct [
    :user,
    :key,
    :cert
  ]

  @doc "Parse #{@moduledoc}"
  @spec parse(any) :: {:ok, t} | {:error, atom}
  def parse(%{user: auth, name: name}) do
    with {:ok, user_key} <- Base.decode64(auth[:"client-key-data"] || ""),
         {:ok, user_cert} <- Base.decode64(auth[:"client-certificate-data"] || "") do
      {:ok,
       %__MODULE__{
         user: name,
         key:
           {:RSAPrivateKey,
            user_key
            |> :public_key.pem_decode()
            |> List.first()
            |> elem(1)},
         cert:
           user_cert
           |> :public_key.pem_decode()
           |> List.first()
           |> elem(1)
       }}
    end
  end

  def parse(_), do: {:error, :invalid_certificate_auth}

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{user: user}, _opts), do: "#CertificateAuth<#{user}>"
  end
end
