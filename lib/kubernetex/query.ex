defmodule Kubernetex.Query.Querify do
  @moduledoc false
  defmacro queryfy(name, args) do
    args = Enum.map(args, &Macro.var(&1, nil))
    uargs = Enum.map(args, fn _ -> Macro.var(:_, nil) end)

    quote location: :keep do
      def unquote(name)(error = {:error, _}, unquote_splicing(uargs)), do: error

      def unquote(name)(query, unquote_splicing(args)) when is_atom(query),
        do: unquote(name)(%__MODULE__{resource: query}, unquote_splicing(args))

      def unquote(name)(data = %resource{}, unquote_splicing(args)) when resource != __MODULE__ do
        with {:ok, dumped} <- resource.dump(data) do
          unquote(name)(%__MODULE__{resource: resource, data: dumped}, unquote_splicing(args))
        end
      end
    end
  end
end

defmodule Kubernetex.Query do
  defmacro __using__(opts \\ []) do
    aliases =
      if opts[:schemas] do
        quote do
          alias Kubernetex.{Container, Deployment, Ingress, Namespace, Pod, Service, Template}
        end
      end

    opts = Keyword.delete(opts, :schemas)

    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__), unquote(opts)
      unquote(aliases)
    end
  end

  alias Kubernetex.{Container, Deployment, Namespace, Service, Template}

  defstruct [
    :resource,
    data: %{}
  ]

  require __MODULE__.Querify
  import __MODULE__.Querify, only: [queryfy: 2]

  def resolve(%__MODULE__{resource: resource, data: data}), do: resource.parse(data)
  def resolve(resource = %_{}), do: {:ok, resource}

  import Kernel, except: [put_in: 3, get_in: 2]

  queryfy(:name, [:name])

  def name(query = %__MODULE__{resource: Container}, name),
    do: put_in(query, [:data, :name], name)

  def name(query, name), do: put_in(query, [:data, :metadata, :name], name)

  queryfy(:namespace, [:namespace])

  def namespace(query, %Namespace{metadata: %{name: name}}),
    do: put_in(query, [:data, :metadata, :namespace], name)

  def namespace(query, namespace),
    do: put_in(query, [:data, :metadata, :namespace], namespace)

  queryfy(:labels, [:labels])

  def labels(query = %__MODULE__{resource: resource}, labels) do
    labels = Map.new(labels)
    update_in(query, [:data, :metadata, :labels], labels, &Map.merge(&1, labels))
  end

  queryfy(:selector, [:selectors])

  def selector(query = %__MODULE__{resource: resource}, selectors) do
    selectors = Map.new(selectors)

    case resource do
      Service ->
        update_in(query, [:data, :spec, :selector], selectors, &Map.merge(&1, selectors))

      Deployment ->
        update_in(
          query,
          [:data, :spec, :selector, :match_labels],
          selectors,
          &Map.merge(&1, selectors)
        )

      _ ->
        {:error, :can_not_apply_selectors}
    end
  end

  ### Very Specific ###

  queryfy(:cluster_ip, [:ip])
  def cluster_ip(query, ip), do: put_in(query, [:data, :spec, :cluster_ip], ip)

  queryfy(:backend, [:service_name, :service_port])

  def backend(query, service_name, service_port) do
    backend = %{service_name: service_name, service_port: service_port}
    put_in(query, [:data, :spec, :backend], backend)
  end

  queryfy(:drop_port, [:port])

  def drop_port(query = %__MODULE__{resource: resource}, port) do
    case resource do
      Service -> update_in(query, [:data, :spec, :ports], [], &delete_port(&1, port))
      Container -> update_in(query, [:data, :ports], [], &delete_port(&1, port))
      _ -> {:error, :can_not_apply_port}
    end
  end

  def port(query, port, settings \\ [])
  queryfy(:port, [:port, :settings])

  def port(query = %__MODULE__{resource: resource}, port, settings) do
    case resource do
      Service ->
        port = settings |> Map.new() |> Map.put(:port, port)
        update_in(query, [:data, :spec, :ports], [port], &set_port(&1, port))

      Container ->
        port = settings |> Map.new() |> Map.put(:container_port, port)
        update_in(query, [:data, :ports], [port], &set_port(&1, port))

      _ ->
        {:error, :can_not_apply_port}
    end
  end

  queryfy(:image, [:image])

  def image(query = %__MODULE__{resource: resource}, image) do
    case resource do
      Container -> put_in(query, [:data, :image], image)
      _ -> {:error, :can_not_apply_image}
    end
  end

  queryfy(:template, [:template])

  def template(query, template) do
    with {:ok, t = %type{}} <- resolve(template),
         {:ok, template} <- type.dump(t) do
      put_in(query, [:data, :spec, :template], template)
    end
  end

  queryfy(:container, [:container])

  def container(query = %__MODULE__{resource: resource}, container) do
    with {:ok, c = %type{}} <- resolve(container),
         {:ok, container} <- type.dump(c) do
      case resource do
        Template ->
          update_in(
            query,
            [:data, :spec, :containers],
            [container],
            &add_container(&1, container)
          )

        Deployment ->
          update_in(
            query,
            [:data, :spec, :template, :spec, :containers],
            [container],
            &add_container(&1, container)
          )
      end
    end
  end

  queryfy(:replicas, [:replicas])
  def replicas(query, replicas), do: put_in(query, [:data, :spec, :replicas], replicas)

  ### Helpers ###

  defp put_in(map, keys, value)

  defp put_in(map, [key], value), do: Map.put(map, key, value)

  defp put_in(map, [key | keys], value) do
    case Map.get(map, key) do
      nil -> Map.put(map, key, put_in(%{}, keys, value))
      data = %{} -> Map.put(map, key, put_in(data, keys, value))
      _ -> raise "Data mismatch."
    end
  end

  defp get_in(map, keys)
  defp get_in(data, []), do: data

  defp get_in(map, [key | keys]) when is_map(map),
    do: if(v = Map.get(map, key), do: get_in(v, keys))

  defp update_in(map, keys, default, updater) do
    case get_in(map, keys) do
      nil -> put_in(map, keys, default)
      update -> put_in(map, keys, updater.(update))
    end
  end

  defp set_port(ports, port = %{port: p}) do
    [port | Enum.reject(ports, &(&1.port == p))]
  end

  defp delete_port(_ports, :all), do: []
  defp delete_port(ports, port), do: Enum.reject(ports, &(&1.port == port or &1.name == port))

  defp add_container(containers, container = %{name: name}) do
    [container | Enum.reject(containers, &(&1.name == name))]
  end
end
