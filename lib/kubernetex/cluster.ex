defmodule Kubernetex.Cluster do
  defmacro __using__(opts \\ []) do
    quote do
      use Kubernetex.Cluster.Config, unquote(opts)
      use Kubernetex.Cluster.API
      use Kubernetex.Cluster.Convenience
      require Logger

      def apply(query) do
        with {:ok, apply} <- Kubernetex.Query.resolve(query) do
          with {:ok, applied} <-
                 if(apply.metadata.uid == :generated, do: create(apply), else: edit(apply)),
               {:ok, _} <-
                 EnumX.map(query.hooks.post, & &1.(__MODULE__, applied)) do
            {:ok, applied}
          end
        end
      end

      def delete(%resource{metadata: %{name: name, namespace: ns}}, opts \\ []) do
        with {:ok, path} <- path(resource, Keyword.put(opts, :namespace, ns)),
             {:ok, _data} <- do_delete("#{path}/#{name}") do
          :ok
        end
      end

      defp path(resource, opts) do
        case resource.__api__(:path) do
          {pre_ns, post_ns} ->
            ns = opts[:namespace]

            cond do
              resource == Kubernetex.Namespace -> {:ok, String.trim_trailing(pre_ns, "/")}
              is_binary(ns) -> {:ok, pre_ns <> ns <> post_ns}
              is_map(ns) -> {:ok, pre_ns <> ns.metadata.name <> post_ns}
              resource != Kubernetex.Namespace -> {:ok, pre_ns <> "default" <> post_ns}
            end

          _ ->
            {:error, :invalid_resource}
        end
      end

      def list!(resource, opts \\ []) do
        case list(resource, opts) do
          {:ok, result} -> result
          {:error, reason} -> raise inspect(reason)
        end
      end

      def list(resource, opts \\ []) do
        with {:ok, path} <- path(resource, opts),
             {:ok, data} <- get(path) do
          EnumX.map(data.items, &resource.parse/1)
        end
      end

      def read(resource, name, opts \\ []) do
        with {:ok, path} <- path(resource, opts),
             {:ok, data} <- get("#{path}/#{name}") do
          resource.parse(data)
        end
      end

      def create(data = %_{}), do: do_create(data, [])

      def create(resource, data_or_opts)
      def create(data = %_{}, opts) when is_list(opts), do: do_create(data, opts)
      def create(resource, data) when is_map(data), do: create(resource, data, [])

      def create(resource, data, opts) do
        with {:ok, data} <- resource.parse(data), do: do_create(data, opts)
      end

      defp do_create(data = %resource{}, opts) do
        params = Enum.reduce(opts, %{}, &create_opts/2)

        with {:ok, path} <- path(resource, namespace: data.metadata.namespace),
             {:ok, submit} <- resource.dump(data),
             submit <- Map.put(submit, :kind, resource.__api__(:kind)),
             {:ok, result} <- post(path, {:json, submit}, params) do
          resource.parse(result)
        end
      end

      def edit(data = %resource{}, opts \\ []) do
        params = Enum.reduce(opts, %{}, &create_opts/2)

        with {:ok, path} <- path(resource, namespace: data.metadata.namespace),
             path <- path <> "/#{data.metadata.name}",
             {:ok, submit} <- resource.dump(data),
             submit <- Map.put(submit, :kind, resource.__api__(:kind)),
             {:ok, result} <- patch(path, {:json, submit}, params) do
          resource.parse(result)
        end
      end

      defp create_opts({:dry_run, value}, acc) when value in [true, false, :all] do
        if value in [true, :all] do
          Map.put(acc, "dryRun", "All")
        else
          Map.delete(acc, "dryRun")
        end
      end

      defp create_opts({option, value}, acc) do
        Logger.warn(fn -> "Unknown create option `:#{option}` or value `#{inspect(value)}`." end)
        acc
      end

      def logs(pod, opts \\ [])

      def logs(pod = %Kubernetex.Pod{}, opts) do
        logs(pod.metadata.name, Keyword.put(opts, :namespace, pod.metadata.namespace))
      end

      def logs(pod, opts) do
        namespace = opts[:namespace] || "kube-system"
        container = opts[:container] || nil
        timestamps = to_string(opts[:timestamps] || false)

        with {:error, %Jason.DecodeError{data: data}} <-
               get("/api/v1/namespaces/#{namespace}/pods/#{pod}/log", %{
                 container: container,
                 timestamps: timestamps,
                 follow: if(opts[:follow], do: "true", else: "false")
               }) do
          {:ok, data}
        end
      end

      def debug do
        IO.puts("Host:            #{__config__(:url)}")
        IO.puts("Version:         #{__config__(:version).git_version}")
        %{core: core, apis: apis} = __config__(:api)

        [v | vs] =
          core
          |> Kernel.++(apis)
          |> List.flatten()
          |> Enum.map(fn %{group: g, preferred: p} ->
            "  - #{g} #{if(p, do: "*", else: "")}"
          end)
          |> Enum.sort()

        IO.puts("Supported APIs: #{v}")
        Enum.each(vs, &IO.puts(["                ", &1]))
      end
    end
  end
end
