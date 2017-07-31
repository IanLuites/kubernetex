use Mix.Config

config :kubernetex,
  url: System.get_env("KUBE_API_URL"),
  secret: System.get_env("KUBE_SECRET")
