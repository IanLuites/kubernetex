defmodule Kubex.Ingress do
  import Util

  @doc false
  def __resource__ do
    "ingresses"
  end

  @doc false
  def __default__ do
    %{
      kind: __MODULE__,
      apiVersion: :"extensions/v1beta1",
    }
  end

  def annotations(object = %{kind: __MODULE__}, annotations) do
    object
    |> put_in_c([:metadata, :annotations], Enum.into(annotations, %{}))
  end

  def paths(object = %{kind: __MODULE__}, host, paths, options \\ []) do
    secret = Keyword.get(options, :secret, String.replace(host, ".", "-") <> "-tls")
    tls =
      %{
        hosts: [host],
        secretName: secret,
      }

    rule =
      %{
        host: host,
        http: %{
          paths: paths,
        }
      }

    object
    |> put_in_c([:spec, :tls], [tls])
    |> put_in_c([:spec, :rules], [rule])
  end

  defmodule Path do
    defstruct [
      :service,
      :port,
      :path,
    ]
  end

  defimpl Poison.Encoder, for: Path do
    @doc false
    def encode(path, options) do
      %{
        path: path.path,
        backend: %{
          serviceName: path.service,
          servicePort: path.port,
        }
      }
      |> Poison.encode!(options)
    end
  end
end

# apiVersion: extensions/v1beta1
# kind: Ingress
# metadata:
#   name: ci-bot
#   namespace: gocd
#   annotations:
#     kubernetes.io/tls-acme: "true"
#     kubernetes.io/ingress.class: "nginx"
# spec:
#   tls:
#   - hosts:
#     - gocd.spiritai.com
#     secretName: gocd-tls
#   rules:
#   - host: gocd.spiritai.com
#     http:
#       paths:
#       - path: /webhook
#         backend:
#           serviceName: ci-bot
#           servicePort: 3000
#       - path: /metrics
#         backend:
#           serviceName: ci-bot
#           servicePort: 3000
