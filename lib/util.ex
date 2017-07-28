defmodule Util do
  def put_in_c(map, [key], value), do: Map.put(map, key, value)
  def put_in_c(map, [key | keys], value) do
    case Map.get(map, key) do
      nil -> Map.put(map, key, create_nested(keys, value))
      data -> Map.put(map, key, put_in_c(data, keys, value))
    end
  end

  def create_nested([key], value), do: Map.put(%{}, key, value)
  def create_nested([key | keys], value) do
    Map.put(%{}, key, create_nested(keys, value))
  end
end
