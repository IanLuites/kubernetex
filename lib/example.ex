defmodule Test do
  use Kubex

  def cleanup do
    Namespace
    |> name("test")
    |> delete
  end

  def setup(options \\ []) do
    # Namespace
    Namespace
    |> name("test")
    |> create(options)

    # Service
    port = %Service.Port{target_port: 8080, port: 80}

    Service
    |> name("example", "test")
    |> ports([port])
    |> selector(app: "example")
    |> create(options)

    # Deployment
    container =
      %Container{
        name: "example",
        image: "gcr.io/google_containers/echoserver:1.4",
        imagePullPolicy: :always,
        env: [
          {"REPLACE_OS_VARS", "true"},
        ],
        ports: [8080],
      }

    Deployment
    |> name("example", "test")
    |> replicas(1)
    |> labels(app: "example")
    |> containers([container], ["docker-registry-secret"])
    |> create(options)

    # Ingress
    path =
      %Path{
        path: "/",
        service: "example",
        port: 80,

      }

    Ingress
    |> name("example", "test")
    |> annotations(["kubernetes.io/tls-acme": "true", "kubernetes.io/ingress.class": "nginx"])
    |> paths("echo.example.com", [path])
    |> create(options)
  end
end
