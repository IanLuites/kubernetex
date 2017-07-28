# Kubex

Kubernetes library for Elixir.

**Note:** Up to the *0.1* release there might be sudden changes to the api.

## Installation

Install by adding `kubex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:kubernetex, "~> 0.0.1"}]
end
```

The docs can be found at [https://hexdocs.pm/kubernetex](https://hexdocs.pm/kubernetex).

## Configuration

```elixir
config :kubex,
  url: "https://x.x.x.x/",
  secret: "secret.json"
```

Set the secret file that contains the Kubernetes credentials.

## Usage
Add the following line `use Kubex` to each module that uses Kubernetes.

### Namespace
```elixir
Namespace
|> name("example")
|> create
```

### Service
```elixir
port = %Service.Port{target_port: 8080, port: 80}

Service
|> name("echo", "example")
|> ports([port])
|> selector(app: "echo")
|> create
```

### Deployment
```elixir
container =
  %Container{
    name: "echo",
    image: "gcr.io/google_containers/echoserver:1.4",
    imagePullPolicy: :always,
    env: [
      {"REPLACE_OS_VARS", "true"},
    ],
    ports: [8080],
  }

Deployment
|> name("echo", "example")
|> replicas(1)
|> labels(app: "echo")
|> containers([container], ["docker-registry-secret"])
|> create
```

### Namespace
```Ingress
path =
  %Path{
    path: "/",
    service: "echo",
    port: 80,

  }

Ingress
|> name("echo", "example")
|> annotations(["kubernetes.io/tls-acme": "true", "kubernetes.io/ingress.class": "nginx"])
|> paths("echo.example.com", [path])
|> create
```

### Options
It is possible to pass the option `dry: true` to `&create/1`.
The `dry` option will output the use URL and posted JSON
without actually creating the resource.
