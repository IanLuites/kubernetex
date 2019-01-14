defmodule Kubernetex.Cluster.Config do
  @type t :: %__MODULE__{}
  defstruct [
    :api,
    :auth,
    :certificate,
    :pool,
    :proxy,
    :url,
    :version
  ]

  ### Helpers ###

  def config(opts) do
    if file = opts[:config] do
      with {:ok, data} <- YamlElixir.read_from_file(file), do: {:ok, MapX.atomize(data)}
    else
      {:ok, nil}
    end
  end

  def proxy(opts) do
    proxy = opts[:proxy]

    cond do
      is_binary(proxy) ->
        uri = URI.parse(proxy)
        {:ok, {String.to_atom(uri.scheme), String.to_charlist(uri.host), uri.port}}

      is_tuple(proxy) ->
        {:ok, proxy}

      :no_proxy ->
        {:ok, nil}
    end
  end

  def url(%{clusters: clusters}, opts) do
    cluster =
      if id = opts[:cluster],
        do: Enum.find(clusters, &(&1.name == id)),
        else: clusters |> List.first()

    cond do
      url = get_in(cluster || %{}, [:cluster, :server]) -> {:ok, url}
      url = opts[:url] -> {:ok, url}
      :error -> {:error, :missing_url}
    end
  end

  def url(nil, opts) do
    if url = opts[:url], do: {:ok, url}, else: {:error, :missing_url}
  end

  def old_url(config, cluster \\ nil)
  def old_url(config, nil), do: config.clusters |> List.first() |> get_in([:cluster, :server])

  def old_url(config, cluster),
    do:
      config.clusters
      |> Enum.find(&(&1.name == cluster))
      |> Kernel.||(%{})
      |> get_in([:cluster, :server])

  def certificate(%{clusters: clusters}, opts) do
    cluster =
      if id = opts[:cluster],
        do: Enum.find(clusters, &(&1.name == id)),
        else: clusters |> List.first()

    if cert = get_in(cluster || %{}, [:cluster, :"certificate-authority-data"]) do
      certificate(nil, Keyword.put(opts, :certificate, cert))
    else
      certificate(nil, opts)
    end
  end

  def certificate(_, opts) do
    if cert = opts[:certificate] do
      with {:ok, data} <- Base.decode64(cert) do
        {:ok,
         data
         |> :public_key.pem_decode()
         |> List.first()
         |> elem(1)}
      end
    else
      {:ok, nil}
    end
  end

  def authentication(%{users: users}, opts) do
    user = if id = opts[:user], do: Enum.find(users, &(&1.name == id)), else: List.first(users)
    if user, do: Kubernetex.Cluster.Auth.Certificate.parse(user), else: authentication(nil, opts)
  end

  ### Parsing ###

  def parse(cluster, opts) do
    opts =
      if otp = opts[:otp_app] do
        Keyword.merge(opts, Application.get_env(otp, cluster, []))
      else
        opts
      end

    result = %__MODULE__{pool: cluster}

    with {:ok, config} <- config(opts),
         {:ok, url} <- url(config, opts),
         {:ok, cert} <- certificate(config, opts),
         {:ok, proxy} <- proxy(opts),
         {:ok, auth} <- authentication(config, opts),
         result = %{result | url: url, proxy: proxy, auth: auth, certificate: cert},
         {:ok, raw_version} <- Kubernetex.Cluster.API.get(result, "/version"),
         {:ok, version} <- Kubernetex.Cluster.Version.parse(raw_version),
         {:ok, apis} <- Kubernetex.Cluster.API.Versions.parse(result) do
      {:ok, %{result | version: version, api: apis}}
    end
  end

  ### Config Server ###

  @moduledoc false
  defmacro __using__(opts \\ []) do
    quote location: :keep do
      ### Config GenServer ###

      use GenServer
      require Logger

      def child_spec(_ \\ []),
        do: %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, []}
        }

      def start_link do
        with {:ok, config} <- Kubernetex.Cluster.Config.parse(__MODULE__, unquote(opts)) do
          Logger.info(fn ->
            "Kubernetex connected to v#{config.version.git_version} cluster. (#{config.url})"
          end)

          GenServer.start_link(__MODULE__, config, name: __MODULE__)
        end
      end

      def __config__, do: GenServer.call(__MODULE__, :config)

      def __config__(field) do
        config = __config__()

        Map.get_lazy(config, field, fn ->
          :erlang.apply(Kubernetex.Cluster.Config, field, [config])
        end)
      end

      @impl GenServer
      def init(config) do
        {:ok, config}
      end

      @impl GenServer
      def handle_call(:config, _from, config) do
        {:reply, config, config}
      end
    end
  end
end
