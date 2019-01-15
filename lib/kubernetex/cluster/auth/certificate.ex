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
    with {:ok, user_key} <- key(auth),
         {:ok, user_cert} <- cert(auth) do
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

  defp key(%{"client-key-data": data}), do: Base.decode64(data)
  defp key(%{"client-key": file}), do: File.read(file)
  defp key(_), do: {:error, :no_client_key}

  defp cert(%{"client-certificate-data": data}), do: Base.decode64(data)
  defp cert(%{"client-certificate": file}), do: File.read(file)
  defp cert(_), do: {:error, :no_client_key}

  defimpl Inspect, for: __MODULE__ do
    def inspect(%{user: user}, _opts), do: "#CertificateAuth<#{user}>"
  end
end
