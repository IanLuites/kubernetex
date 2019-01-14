defmodule Kubernetex.Container.Status do
  @moduledoc ~S"""
  ## Fields

  ### container_id (`string`)
  Container's ID in the format 'docker://<container_id>'.

  ### image (`string`)
  The image the container is running.

  ### image_id (`string`)
  Image ID of the container's image.

  ### last_state (`Kubernetex.Container.State`)
  Details about the container's last termination condition.

  ### name (`DNS_LABEL`)
  Each container in a pod must have a unique name.
  Cannot be updated.

  ### ready (`boolean`)
  Specifies whether the container has passed its readiness probe.

  ### restart_count (`non_neg_integer`)
  The number of times the container has been restarted,
  currently based on the number of dead containers that have not yet been removed.
  Note that this is calculated from dead containers.
  But those containers are subject to garbage collection.
  This value will get capped at 5 by GC.

  ### state (`Kubernetex.Container.State`)
  Details about the container's current condition.
  """

  use Kubernetex.Structure

  defstructure version: "core/v1" do
    field :container_id, :string, required: false, default: nil
    field :image, Kubernetex.Docker, required: true
    field :image_id, :string, required: false, default: nil
    field :last_state, Kubernetex.Container.State, required: false, default: nil
    field :name, :dns_label, required: true
    field :ready, :boolean, required: false, default: false
    field :restart_count, :non_neg_integer, required: false, default: 0
    field :state, Kubernetex.Container.State, required: false, default: nil
  end
end
