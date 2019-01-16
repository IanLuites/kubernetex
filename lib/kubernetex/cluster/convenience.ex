defmodule Kubernetex.Cluster.Convenience do
  defmacro __using__(_opts \\ []) do
    Enum.reduce(
      [
        Kubernetex.Deployment,
        Kubernetex.Ingress,
        Kubernetex.Namespace,
        Kubernetex.Secret,
        Kubernetex.Service
      ],
      nil,
      fn resource, acc ->
        base =
          resource
          |> to_string
          |> String.split(".", trim: true)
          |> List.last()
          |> Macro.underscore()

        quote do
          unquote(acc)

          def unquote(:"#{base}")(name, opts \\ []), do: read(unquote(resource), name, opts)
          def unquote(:"#{base}s")(opts \\ []), do: list(unquote(resource), opts)

          def unquote(:"create_#{base}")(data, opts \\ []),
            do: create(unquote(resource), data, opts)
        end
      end
    )
  end
end
