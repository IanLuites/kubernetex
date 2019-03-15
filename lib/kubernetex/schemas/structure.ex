defmodule Kubernetex.Structure do
  defmacro __using__(_opts \\ []) do
    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__), only: [defstructure: 2]
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro defstructure(opts, structure) do
    version = opts[:version] || raise "Need to set version."
    kind = opts[:kind]

    pre_ns =
      if String.starts_with?(version, "core/") do
        "/api/#{String.trim_leading(version, "core/")}/namespaces/"
      else
        "/apis/#{version}/namespaces/"
      end

    post_ns =
      if kind do
        kind_snake = "/#{String.downcase(kind)}"

        if String.ends_with?(kind_snake, "s"), do: kind_snake <> "es", else: kind_snake <> "s"
      else
        ""
      end

    quote do
      Module.register_attribute(__MODULE__, :struct_fields, accumulate: true)
      @type t :: %__MODULE__{}

      try do
        import unquote(__MODULE__)
        unquote(structure)
      after
        :ok
      end

      @enforce_keys @struct_fields
                    |> Enum.filter(fn {_, v} -> v.required end)
                    |> Enum.map(&elem(&1, 0))
      defstruct Enum.map(@struct_fields, fn {k, v} -> {k, v.default} end)

      def __api__(:version), do: unquote(version)
      def __api__(:kind), do: unquote(kind)
      def __api__(:path), do: {unquote(pre_ns), unquote(post_ns)}

      @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, term}
      def validate(data), do: {:ok, data}

      defoverridable validate: 1
    end
  end

  defmacro field(name, type, opts \\ []) do
    quote do
      Module.put_attribute(
        __MODULE__,
        :struct_fields,
        {unquote(name),
         %{
           type: unquote(type),
           required: unquote(opts[:required] || false),
           default: unquote(opts[:default]),
           dump: unquote(opts[:dump] != false),
           camelized: unquote(opts[:camelized] || MacroX.camelize(name))
         }}
      )
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    parsers =
      env.module
      |> Module.get_attribute(:struct_fields)
      |> Enum.map(fn {field, settings} ->
        parser = parser(settings.type)

        on_error =
          if(settings.required,
            do: {:error, :"error_missing_#{field}"},
            else: {:ok, field, settings.default}
          )

        quote do
          fn data ->
            value =
              case MapX.fetch(data, unquote(field)) do
                :error -> MapX.fetch(data, unquote(settings.camelized))
                ok -> ok
              end

            with {:ok, value} <- value,
                 {:ok, parsed} <- unquote(parser).(value) do
              {:ok, unquote(field), parsed}
            else
              :error -> unquote(Macro.escape(on_error))
              error = {:error, _} -> error
            end
          end
        end
      end)

    dumpers =
      env.module
      |> Module.get_attribute(:struct_fields)
      |> Enum.reject(fn {_, settings} -> settings[:dump] == false end)
      |> Enum.map(fn {field, settings} ->
        dumper = dumper(settings.type)

        quote do
          fn data, opts ->
            value = data[unquote(field)]

            if is_nil(value) or value == %{} do
              :skip
            else
              with {:ok, dumped} <- unquote(dumper).(value, opts) do
                case opts[:keys] || :camel do
                  :camel -> {:ok, unquote(settings.camelized), dumped}
                  :snake -> {:ok, unquote(field), dumped}
                end
              end
            end
          end
        end
      end)

    quote do
      @spec parse(map) :: {:ok, __MODULE__.t()} | {:error, term}
      def parse(data) do
        with {:ok, parsed} <- MapX.new(unquote(parsers), & &1.(data)) do
          validate(struct!(__MODULE__, parsed))
        end
      end

      @spec dump(__MODULE__.t(), Keyword.t()) :: {:ok, map} | {:error, term}
      def dump(resource, opts \\ []) do
        data = Map.from_struct(resource)

        MapX.new(unquote(dumpers), & &1.(data, opts))
      end

      defimpl Jason.Encoder, for: __MODULE__ do
        alias Jason.Encode
        @doc false
        @spec encode(any, Keyword.t()) :: any
        def encode(value, opts) do
          value
          |> unquote(__CALLER__.module).dump()
          |> elem(1)
          |> Encode.map(opts)
        end
      end
    end
  end

  # &EnumX.map(&1, parser(type))
  def parser({:array, type}) do
    quote do
      fn array -> EnumX.map(array, unquote(parser(type))) end
    end
  end

  def parser({:either, type1, type2}) do
    quote do
      fn value ->
        with {:error, _} <- unquote(parser(type1)).(value), do: unquote(parser(type2)).(value)
      end
    end
  end

  def parser({:map, key_type, value_type}) do
    quote do
      fn map ->
        MapX.new(map, fn {k, v} ->
          with {:ok, key} <- unquote(parser(key_type)).(k),
               {:ok, value} <- unquote(parser(value_type)).(v) do
            {:ok, key, value}
          end
        end)
      end
    end
  end

  def parser({:enum, values}) do
    lookup =
      values
      |> Enum.flat_map(
        &[
          {&1, &1},
          {to_string(&1), &1},
          {MacroX.camelize(to_string(&1)), &1},
          {MacroX.pascalize(to_string(&1)), &1}
        ]
      )
      |> Map.new(fn {k, v} -> {k, {:ok, v}} end)

    quote do
      fn x ->
        unquote(Macro.escape(lookup))[x] || {:error, :invalid_enum}
      end
    end
  end

  @primitives %{
    # General
    boolean: Kubernetex.Primitives.Boolean,
    integer: Kubernetex.Primitives.Integer,
    map: Kubernetex.Primitives.Map,
    non_neg_integer: Kubernetex.Primitives.NonNegativeInteger,
    string: Kubernetex.Primitives.String,
    timestamp: Kubernetex.Primitives.Timestamp,

    # Network
    ip: Kubernetex.Primitives.IP,
    port: Kubernetex.Primitives.Port,
    protocol: Kubernetex.Primitives.Protocol,

    # Kubernetex
    c_identifier: Kubernetex.Primitives.CIndentifier,
    dns_label: Kubernetex.Primitives.DNSLabel,
    dns_subdomain: Kubernetex.Primitives.DNSSubdomain,
    iana_svc_name: Kubernetex.Primitives.IANASvcName,
    message: Kubernetex.Primitives.Message,
    reason: Kubernetex.Primitives.Reason
  }

  def parser(type) do
    if primitive = @primitives[type], do: &primitive.parse/1, else: &type.parse/1
  end

  def dumper({:array, type}) do
    quote do
      fn array, opts -> EnumX.map(array, &unquote(dumper(type)).(&1, opts)) end
    end
  end

  def dumper({:either, type1, _}) do
    # Requires some logic
    dumper(type1)
  end

  def dumper({:map, key_type, value_type}) do
    quote do
      fn map, opts ->
        MapX.new(map, fn {k, v} ->
          with {:ok, key} <- unquote(dumper(key_type)).(k, opts),
               {:ok, value} <- unquote(dumper(value_type)).(v, opts) do
            {:ok, key, value}
          end
        end)
      end
    end
  end

  def dumper({:enum, _values}) do
    quote do
      fn value, _opts -> {:ok, MacroX.pascalize(to_string(value))} end
    end
  end

  def dumper(type) do
    if primitive = @primitives[type], do: &primitive.dump/2, else: &type.dump/2
  end
end
