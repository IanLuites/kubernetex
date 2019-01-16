defmodule Kubernetex.Docker do
  @moduledoc ~S"""
  Docker image.
  """
  @typedoc @moduledoc
  @type t :: %__MODULE__{
          registry: String.t() | nil,
          organization: String.t() | nil,
          image: String.t(),
          tag: String.t()
        }

  defstruct [
    :registry,
    :organization,
    :image,
    :tag
  ]

  @doc ~S"""
  See: `parse/1`.
  """
  @spec parse!(any) :: t | no_return
  def parse!(value) do
    case parse(value) do
      {:ok, result} -> result
      {:error, reason} -> raise "Invalid docker image: #{reason}"
    end
  end

  @doc ~S"""
  Parse a string to a docker image.
  """
  @spec parse(any) :: {:ok, t} | {:error, :invalid_docker_image}
  def parse(docker = %__MODULE__{}), do: {:ok, docker}

  def parse(value) when is_binary(value) do
    input =
      Regex.named_captures(
        ~r/^(?<registry>[a-z0-9:\.\/\-]+?\/)??((?<org>[a-z0-9\-_]+)\/)?(?<image>[a-z0-9\-_]+)(\:(?<tag>[a-z0-9\.\-]+))?$/,
        value
      )

    if image = input["image"] do
      org = input["org"] || ""
      tag = input["tag"] || ""
      registry = input["registry"] || ""

      {:ok,
       %__MODULE__{
         image: image,
         organization: if(org == "", do: nil, else: org),
         registry:
           case registry do
             nil -> nil
             "" -> nil
             "hub.docker.com" -> nil
             "https://hub.docker.com" -> nil
             reg -> String.trim_trailing(reg, "/")
           end,
         tag: if(tag == "", do: "latest", else: tag)
       }}
    else
      {:error, :invalid_docker_image}
    end
  end

  def parse(_), do: {:error, :invalid_docker_image}

  def dump(value), do: {:ok, to_string(value)}

  defimpl Inspect, for: __MODULE__ do
    @doc false
    @spec inspect(map, Keyword.t()) :: String.t()
    def inspect(%{organization: org, image: image, tag: tag}, _opts) do
      tag = if(tag == "latest", do: "", else: ":#{tag}")
      org = if(org, do: "#{org}/", else: "")

      "#Docker<#{org}#{image}#{tag}>"
    end
  end

  defimpl String.Chars, for: __MODULE__ do
    @doc false
    @spec to_string(map) :: String.t()
    def to_string(docker) do
      url =
        [docker.registry, docker.organization, docker.image]
        |> Enum.reject(&is_nil/1)
        |> Enum.join("/")

      if docker.tag, do: "#{url}:#{docker.tag}", else: url
    end
  end
end
