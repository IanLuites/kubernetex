defmodule Kubex.Service do
  @doc false
  def __resource__ do
    "services"
  end

  @doc false
  def __default__ do
    %{
      kind: __MODULE__,
      apiVersion: :v1,
    }
  end

  def ports(object = %{kind: __MODULE__}, ports) do
    object
    |> Map.put_new(:spec, %{})
    |> put_in([:spec, :ports], ports)
  end

  def selector(object = %{kind: __MODULE__}, selector) do
    object
    |> Map.put_new(:spec, %{})
    |> put_in([:spec, :selector], Enum.into(selector, %{}))
  end

  defmodule Port do
    @enforce_keys [:port, :target_port]
    defstruct [
      :port,
      :target_port,
      name: nil,
      protocol: :TCP,
    ]
  end

  defimpl Poison.Encoder, for: Port do
    @doc false
    def encode(port, options) do
      data =
        %{
          name: port.name,
          port: port.port,
          targetPort: port.target_port,
          protocol: port.protocol,
        }

      if port.name do
        data
        |> Poison.encode!(options)
      else
        data
        |> Map.delete(:name)
        |> Poison.encode!(options)
      end
    end
  end
end
