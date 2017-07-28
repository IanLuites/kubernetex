defmodule Kubex do
  alias Kubex.Deployment
  alias Kubex.Ingress
  alias Kubex.Namespace
  alias Kubex.Service

  defmacro __using__(_options \\ []) do
    quote do
      alias Kubex.Deployment
      alias Kubex.Deployment.Container
      alias Kubex.Ingress
      alias Kubex.Ingress.Path
      alias Kubex.Namespace
      alias Kubex.Service
      alias Kubex.Service.Port

      import Kubex
      import Deployment, except: [__resource__: 0]
      import Ingress, except: [__resource__: 0]
      import Namespace, except: [__resource__: 0]
      import Service, except: [__resource__: 0]
    end
  end

  def api(module, version) when is_atom(module) do
    module.__default__
    |> api(version)
  end

  def api(object, version) do
    Map.put(object, :apiVersion, version)
  end

  def name(module, name, namespace) when is_atom(module) do
    module.__default__
    |> name(name, namespace)
  end

  def name(object, name, namespace) do
    object
    |> Map.put_new(:metadata, %{})
    |> put_in([:metadata, :name], name)
    |> put_in([:metadata, :namespace], namespace || "default")
  end

  def name(module, name) when is_atom(module) do
    module.__default__
    |> name(name)
  end

  def name(object, name) do
    object
    |> Map.put_new(:metadata, %{})
    |> put_in([:metadata, :name], name)
  end

  ### Apply and Delete

  def create(object = %{kind: kind}, options \\ []) do
    pretty =
      case options[:dry] do
        true -> [pretty: true]
        _ -> []
      end

    data =
      object
      |> Map.put(:kind, kind |> to_string |> String.split(".") |> List.last)
      |> Poison.encode!(pretty)

    url = generate_url(object, :post)

    if options[:dry] do
      IO.puts "Post: #{url}\r\n---"
      IO.puts data
      IO.puts "---"
    else
      headers =
        [
          bearer(),
          {"Content-Type", "application/json"},
        ]

      options =
        [
          headers: headers,
          format: :json_atoms,
          settings: [
            ssl_options: [
              {:verify, :verify_none},
              {:server_name_indication, :disable},
            ],
          ],
        ]

      HTTPX.post(url, data, options)
    end
  end

  def delete(object) do
    url = generate_url(object, :delete)

    headers =
      [
        bearer(),
        {"Content-Type", "application/json"},
      ]

    options =
      [
        headers: headers,
        format: :json_atoms,
        settings: [
          ssl_options: [
            {:verify, :verify_none},
            {:server_name_indication, :disable},
          ],
        ],
      ]

    HTTPX.request(:delete, url, options)
  end

  ### Helpers

  defp generate_url(object = %{apiVersion: version, kind: kind, metadata: %{name: name}}, type) do
    base = Application.fetch_env!(:kubernetex, :url)
    api =
      case version do
        :v1 -> "api/v1"
        _ -> "apis/#{version}"
      end

    url =
      if kind in [Namespace] do
        "#{base}#{api}/namespaces"
      else
        resource = kind.__resource__
        namespace = object |> Map.get(:metadata) |> Map.get(:namespace, "default")

        "#{base}#{api}/namespaces/#{namespace}/#{resource}"
      end

    case type do
      :delete -> url <> "/" <> name
      :get -> url <> "/" <> name
      :index -> url
      :post -> url
      :put -> url <> "/" <> name
    end
  end

  defp bearer do
    token =
      :kubernetex
      |> Application.fetch_env!(:secret)
      |> File.read!
      |> Poison.decode!
      |> Map.get("data")
      |> Map.get("token")
      |> Base.decode64!

    {"authorization", "Bearer " <> token}
  end
end
