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
        with {:ok, dumped} <- resource.dump(data, keys: :snake) do
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
          alias Kubernetex.{
            Container,
            Deployment,
            Ingress,
            Namespace,
            Pod,
            Secret,
            Service,
            Template
          }
        end
      end

    opts = Keyword.delete(opts, :schemas)

    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__), unquote(opts)
      unquote(aliases)
    end
  end

  alias Kubernetex.{Container, Deployment, HorizontalPodAutoscaler, Namespace, Service, Template}

  defstruct [
    :resource,
    data: %{},
    hooks: %{
      post: []
    }
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

  queryfy(:annotations, [:annotations])

  def annotations(query, annotations) do
    annotations = Map.new(annotations)
    update_in(query, [:data, :metadata, :annotations], annotations, &Map.merge(&1, annotations))
  end

  queryfy(:labels, [:labels])

  def labels(query, labels) do
    labels = Map.new(labels)
    update_in(query, [:data, :metadata, :labels], labels, &Map.merge(&1, labels))
  end

  queryfy(:type, [:type])

  def type(query, type), do: put_in(query, [:data, :type], type)

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

  queryfy(:rule, [:rule])

  def rule(query, rule) do
    {service_name, service_port} = rule[:backend]
    backend = %{service_name: service_name, service_port: service_port}

    path =
      if p = rule[:path] do
        %{
          path: p,
          backend: backend
        }
      else
        %{
          backend: backend
        }
      end

    put_in(query, [:data, :spec, :rules], [
      %{
        host: rule[:host],
        http: %{paths: [path]}
      }
    ])
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

  queryfy(:image_pull_secret, [:secret])

  def image_pull_secret(query = %__MODULE__{resource: resource}, secret) do
    secret = %{name: secret}

    case resource do
      Template ->
        update_in(
          query,
          [:data, :spec, :image_pull_secrets],
          [secret],
          &Enum.uniq([secret | &1])
        )

      _ ->
        {:error, :can_not_add_secret}
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

  queryfy(:secret, [:key, :value])

  def secret(query, key, value) when is_binary(value) do
    put_in(
      query,
      [:data, :data, to_string(key)],
      Base.encode64(value, padding: true)
    )
  end

  def secret(_, _, _), do: {:error, :secret_value_must_be_binary}

  queryfy(:env_var, [:name, :value])

  def env_var(query = %__MODULE__{resource: resource}, name, value) do
    var = %{name: name, value: value}

    case resource do
      Container ->
        update_in(
          query,
          [:data, :env],
          [var],
          &add_env_var(&1, var)
        )
    end
  end

  queryfy(:env_var, [:name, :value])

  def env_from(query = %__MODULE__{resource: resource}, env_source) do
    env_source = [env_source(env_source)]

    case resource do
      Container ->
        update_in(
          query,
          [:data, :env_from],
          env_source,
          &(&1 ++ env_source)
        )
    end
  end

  queryfy(:limit, [:limit])

  def limit(query = %__MODULE__{resource: resource}, cpu = %Kubernetex.CPU{}) do
    case resource do
      Container -> put_in(query, [:data, :resources, :limits, :cpu], cpu)
    end
  end

  def limit(query = %__MODULE__{resource: resource}, memory = %Kubernetex.Memory{}) do
    case resource do
      Container -> put_in(query, [:data, :resources, :limits, :memory], memory)
    end
  end

  queryfy(:request, [:limit])

  def request(query = %__MODULE__{resource: resource}, cpu = %Kubernetex.CPU{}) do
    case resource do
      Container -> put_in(query, [:data, :resources, :requests, :cpu], cpu)
    end
  end

  def request(query = %__MODULE__{resource: resource}, memory = %Kubernetex.Memory{}) do
    case resource do
      Container -> put_in(query, [:data, :resources, :requests, :memory], memory)
    end
  end

  queryfy(:history_limit, [:limit])

  def history_limit(query, limit),
    do: put_in(query, [:data, :spec, :revision_history_limit], limit)

  queryfy(:scale, [:option])

  def scale(query, false) do
    hook = [
      fn cluster, %{metadata: %{name: name, namespace: ns}} ->
        case cluster.horizontal_pod_autoscaler(name, namespace: ns) do
          {:ok, scaler} -> with :ok <- cluster.delete(scaler), do: {:ok, false}
          {:error, %{reason: "NotFound"}} -> {:ok, false}
          error -> error
        end
      end
    ]

    update_in(
      query,
      [:hooks, :post],
      hook,
      &(&1 ++ hook)
    )
  end

  def scale(query, %{min: min, max: max, cpu: cpu}), do: scale(query, min, max, cpu)

  def scale(query, min, max), do: scale(query, min, max, 50)

  queryfy(:scale, [:min, :max, :cpu])

  def scale(query = %__MODULE__{resource: resource}, min, max, cpu) do
    case resource do
      Deployment ->
        hook = [
          fn cluster, deployment = %{metadata: %{name: name, namespace: ns}} ->
            case cluster.horizontal_pod_autoscaler(name, namespace: ns) do
              {:ok, scaler} ->
                scaler
                |> scale(min, max, cpu)
                |> scale_target_ref(deployment)
                |> cluster.apply()

              {:error, %{reason: "NotFound"}} ->
                HorizontalPodAutoscaler
                |> name(name)
                |> namespace(ns)
                |> scale(min, max, cpu)
                |> scale_target_ref(deployment)
                |> cluster.apply()

              error ->
                error
            end
          end
        ]

        update_in(
          query,
          [:hooks, :post],
          hook,
          &(&1 ++ hook)
        )

      HorizontalPodAutoscaler ->
        query
        |> put_in([:data, :spec, :min_replicas], min)
        |> put_in([:data, :spec, :max_replicas], max)
        |> put_in([:data, :spec, :target_cpu_utilization_percentage], cpu)
    end
  end

  queryfy(:scale_target_ref, [:reference])

  def scale_target_ref(query, reference = %type{}),
    do:
      put_in(query, [:data, :spec, :scale_target_ref], %{
        api_version: type.__api__(:version),
        kind: type.__api__(:kind),
        name: reference.metadata.name
      })

  ### Helpers ###

  alias Kubernetex.Container.EnvFromSource

  defp env_source(source = %EnvFromSource{}),
    do: with({:ok, s} <- EnvFromSource.dump(source), do: s)

  defp env_source(%Kubernetex.Secret{metadata: %{name: name}}) do
    %{secret_ref: %{name: name}}
  end

  defp env_source(source = %t{}) do
    with {:ok, s} <- t.dump(source) do
      case t do
        Kubernetex.SecretEnvSource -> %{secret_ref: s}
        Kubernetex.ConfigMapEnvSource -> %{config_map_ref: s}
      end
    end
  end

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

  defp add_env_var(vars, env_var = %{name: name}) do
    [env_var | Enum.reject(vars, &(&1.name == name))]
  end
end
