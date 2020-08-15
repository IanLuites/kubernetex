defmodule Kubernetex.Cluster.API do
  @moduledoc ~S"""
  Low level Kubernetes API calls.
  """

  @doc @moduledoc
  defmacro __using__(_opts \\ []) do
    quote location: :keep do
      @spec get(String.t(), map) :: {:ok, map} | {:error, any}
      def get(endpoint, params \\ %{}),
        do: unquote(__MODULE__).get(__config__(), endpoint, params)

      @spec post(String.t(), map, map) :: {:ok, map} | {:error, any}
      defp post(endpoint, body, params \\ %{}),
        do: unquote(__MODULE__).post(__config__(), endpoint, body, params)

      @spec patch(String.t(), map, map) :: {:ok, map} | {:error, any}
      defp patch(endpoint, body, params \\ %{}),
        do: unquote(__MODULE__).patch(__config__(), endpoint, body, params)

      @spec do_delete(String.t(), map) :: {:ok, map} | {:error, any}
      defp do_delete(endpoint, params \\ %{}),
        do: unquote(__MODULE__).delete(__config__(), endpoint, params)
    end
  end

  alias Kubernetex.Cluster.Config
  alias Kubernetex.Cluster.Auth.{Certificate, Token}
  require Logger

  @doc false
  @spec get(Config.t(), String.t(), map) :: {:ok, map} | {:error, any}
  def get(config = %Config{url: url}, endpoint, params \\ %{}) do
    Logger.debug(fn -> "Kube GET #{url <> endpoint}" end)

    HTTPX.get(
      url <> endpoint,
      params: params,
      headers: [{"Accept", "application/json"} | auth_headers(config)],
      settings: settings(config)
    )
    |> response
  end

  @doc false
  @spec post(Config.t(), String.t(), map, map) :: {:ok, map} | {:error, any}
  def post(config = %Config{url: url}, endpoint, body, params) do
    Logger.debug(fn -> "Kube POST #{url <> endpoint}" end)

    HTTPX.post(
      url <> endpoint,
      body,
      params: params,
      headers: [{"Accept", "application/json"} | auth_headers(config)],
      settings: settings(config)
    )
    |> response
  end

  @doc false
  @spec patch(Config.t(), String.t(), map, map) :: {:ok, map} | {:error, any}
  def patch(config = %Config{url: url}, endpoint, {:json, body}, params) do
    Logger.debug(fn -> "Kube PATCH #{url <> endpoint}" end)

    with {:ok, body} <- Jason.encode(body) do
      HTTPX.patch(
        url <> endpoint,
        body,
        params: params,
        headers: [
          {"Accept", "application/json"},
          {"Content-Type", "application/merge-patch+json"} | auth_headers(config)
        ],
        settings: settings(config)
      )
    end
    |> response
  end

  @doc false
  @spec delete(Config.t(), String.t(), map) :: {:ok, map} | {:error, any}
  def delete(config = %Config{url: url}, endpoint, params \\ %{}) do
    Logger.debug(fn -> "Kube DELETE #{url <> endpoint}" end)

    HTTPX.delete(
      url <> endpoint,
      params: params,
      headers: [{"Accept", "application/json"} | auth_headers(config)],
      settings: settings(config)
    )
    |> response
  end

  @spec response(any) :: {:ok, map} | {:error, any}
  defp response(error = {:error, _}), do: error

  defp response({:ok, %{status: 403, body: msg}}) do
    {:error, %Kubernetex.Error{reason: "Forbidden", message: msg}}
  end

  defp response({:ok, %{status: status, body: data}}) when status in 200..299 do
    case Jason.decode(data, keys: :atoms) do
      response = {:ok, _} -> response
      _ -> {:ok, data}
    end
  end

  defp response({:ok, %{body: data}}) do
    case Jason.decode(data, keys: :atoms) do
      {:ok, result} ->
        result = result |> Map.delete(:apiVersion) |> Map.put(:api_version, result.apiVersion)
        {:error, struct!(Kubernetex.Error, result)}

      _ ->
        {:ok, :invalid_json_response}
    end
  end

  @spec auth_headers(Config.t()) :: list
  defp auth_headers(config)
  defp auth_headers(%Config{auth: %Certificate{}}), do: []
  defp auth_headers(%Config{auth: %Token{token: t}}), do: [{"authorization", "Bearer #{t}"}]

  @spec settings(Config.t()) :: Keyword.t()
  defp settings(%Config{
         certificate: cert,
         auth: auth = %Certificate{},
         proxy: proxy,
         pool: pool,
         ssl_options: opts
       }) do
    [
      ssl_options: [key: auth.key, cert: auth.cert, cacerts: [cert]] ++ opts,
      pool: pool,
      proxy: proxy
    ]
  end

  defp settings(%Config{certificate: cert, proxy: proxy, pool: pool, ssl_options: opts}) do
    [
      ssl_options: [{:cacerts, [cert]} | opts],
      pool: pool,
      proxy: proxy
    ]
  end
end
