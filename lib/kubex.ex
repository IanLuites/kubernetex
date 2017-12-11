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
      alias Kubex.Pod
      alias Kubex.ReplicaSet
      alias Kubex.Service
      alias Kubex.Service.Port

      import Kubex
      import Deployment, except: [__resource__: 0]
      import Ingress, except: [__resource__: 0]
      import Namespace, except: [__resource__: 0]
      import Pod, except: [__resource__: 0]
      import ReplicaSet, except: [__resource__: 0]
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

  def namespace(module, namespace) when is_atom(module) do
    module.__default__
    |> namespace(namespace)
  end

  def namespace(object, namespace) do
    object
    |> Map.put_new(:metadata, %{})
    |> put_in([:metadata, :namespace], namespace)
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
      |> Map.put(:kind, kind |> to_string |> String.split(".") |> List.last())
      |> Poison.encode!(pretty)

    url = generate_url(object, :post)

    if options[:dry] do
      IO.puts("Post: #{url}\r\n---")
      IO.puts(data)
      IO.puts("---")
    else
      HTTPX.post(url, data, request_options())
    end
  end

  def delete(object) do
    url = generate_url(object, :delete)

    HTTPX.request(:delete, url, request_options())
  end

  ### Find

  def get(object) do
    url = generate_url(object, :get)

    HTTPX.request(:get, url, request_options())
  end

  def list(object) do
    url = generate_url(object, :index)

    with {:ok, data} <- HTTPX.request(:get, url, request_options()),
         %{body: json} <- data,
         %{items: items} <- json do
      {:ok, items}
    else
      error = {:error, _reason} -> error
      _ -> {:error, :can_not_list_resource}
    end
  end

  def log(object, follow \\ false)

  def log(object, true) do
    url = generate_url(object, :log)

    options =
      request_options()
      |> Keyword.delete(:format)
      |> Keyword.put(:params, %{follow: "true"})

    HTTPX.request(:get, url, options)
  end

  def log(object, false) do
    url = generate_url(object, :log)

    options =
      request_options()
      |> Keyword.delete(:format)

    with {:ok, %{body: log}} <- HTTPX.request(:get, url, options) do
      {:ok, log}
    else
      error = {:error, _reason} -> error
      _ -> {:error, :can_not_find_log}
    end
  end

  ### Helpers

  defp generate_url(object = %{apiVersion: version, kind: kind}, type) do
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
      :delete -> url <> "/" <> object.metadata.name
      :get -> url <> "/" <> object.metadata.name
      :index -> url
      :log -> url <> "/" <> object.metadata.name <> "/log"
      :post -> url
      :put -> url <> "/" <> object.metadata.name
    end
  end

  defp generate_url(kind, type) do
    kind.__default__
    |> Map.put(:metadata, %{name: nil})
    |> generate_url(type)
  end

  defp request_options do
    [
      headers: [
        bearer(),
        {"Content-Type", "application/json"}
      ],
      format: :json_atoms,
      settings: [
        ssl_options: [
          {:verify, :verify_none},
          {:server_name_indication, :disable}
        ]
      ]
    ]
  end

  defp bearer do
    token =
      :kubernetex
      |> Application.fetch_env!(:secret)
      |> File.read!()
      |> Poison.decode!()
      |> Map.get("data")
      |> Map.get("token")
      |> Base.decode64!()

    {"authorization", "Bearer " <> token}
  end
end
