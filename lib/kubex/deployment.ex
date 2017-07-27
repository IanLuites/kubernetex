defmodule Kubex.Deployment do
  import Util

  @doc false
  def __resource__ do
    "deployments"
  end

  @doc false
  def __default__ do
    %{
      kind: __MODULE__,
      apiVersion: :"extensions/v1beta1",
    }
  end

  def replicas(object = %{kind: __MODULE__}, replicas) do
    object
    |> put_in_c([:spec, :replicas], replicas)
  end

  def labels(object = %{kind: __MODULE__}, labels) do
    object
    |> put_in_c([:spec, :template, :metadata, :labels], Enum.into(labels, %{}))
  end

  def containers(object = %{kind: __MODULE__}, containers, image_pull_secrets \\ []) do
    object =
      object
      |> put_in_c([:spec, :template, :spec, :containers], containers)

    if image_pull_secrets != [] do
      image_pull_secrets = Enum.map(image_pull_secrets, &(%{name: &1}))

      object
      |> put_in_c([:spec, :template, :spec, :imagePullSecrets], image_pull_secrets)
    else
      object
    end
  end

  defmodule Container do
    defstruct [
      :name,
      :image,
      imagePullPolicy: :always,
      env: [],
      ports: [],
    ]
  end

  defimpl Poison.Encoder, for: Container do
    @doc false
    def encode(container, options) do
      %{
        name: container.name,
        image: container.image,
        imagePullPolicy: container.imagePullPolicy |> to_string |> String.capitalize,
        env: Enum.map(container.env, fn {name, value} -> %{name: name, value: value} end),
        ports: Enum.map(container.ports, &(%{containerPort: &1})),
      }
      |> Poison.encode!(options)
    end
  end
end
