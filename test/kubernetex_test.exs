defmodule KubernetexTest do
  use ExUnit.Case
  doctest Kubernetex

  test "greets the world" do
    assert Kubernetex.hello() == :world
  end
end
