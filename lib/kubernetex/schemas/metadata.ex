defmodule Kubernetex.Metadata do
  @moduledoc ~S"""
  Every object kind MUST have the following metadata in a nested object field
  called "metadata":

  * namespace: a namespace is a DNS compatible label that objects are subdivided
  into. The default namespace is 'default'. See
  [the namespace docs](https://kubernetes.io/docs/user-guide/namespaces/) for more.
  * name: a string that uniquely identifies this object within the current
  namespace (see [the identifiers docs](https://kubernetes.io/docs/user-guide/identifiers/)).
  This value is used in the path when retrieving an individual object.
  * uid: a unique in time and space value (typically an RFC 4122 generated
  identifier, see [the identifiers docs](https://kubernetes.io/docs/user-guide/identifiers/))
  used to distinguish between objects with the same name that have been deleted
  and recreated

  Every object SHOULD have the following metadata in a nested object field called
  "metadata":

  * resourceVersion: a string that identifies the internal version of this object
  that can be used by clients to determine when objects have changed. This value
  MUST be treated as opaque by clients and passed unmodified back to the server.
  Clients should not assume that the resource version has meaning across
  namespaces, different kinds of resources, or different servers. (See
  [concurrency control](#concurrency-control-and-consistency), below, for more
  details.)
  * generation: a sequence number representing a specific generation of the
  desired state. Set by the system and monotonically increasing, per-resource. May
  be compared, such as for RAW and WAW consistency.
  * creationTimestamp: a string representing an RFC 3339 date of the date and time
  an object was created
  * deletionTimestamp: a string representing an RFC 3339 date of the date and time
  after which this resource will be deleted. This field is set by the server when
  a graceful deletion is requested by the user, and is not directly settable by a
  client. The resource will be deleted (no longer visible from resource lists, and
  not reachable by name) after the time in this field except when the object has
  a finalizer set. In case the finalizer is set the deletion of the object is
  postponed at least until the finalizer is removed.
  Once the deletionTimestamp is set, this value may not be unset or be set further
  into the future, although it may be shortened or the resource may be deleted
  prior to this time.
  * labels: a map of string keys and values that can be used to organize and
  categorize objects (see [the labels docs](https://kubernetes.io/docs/user-guide/labels/))
  * annotations: a map of string keys and values that can be used by external
  tooling to store and retrieve arbitrary metadata about this object (see
  [the annotations docs](https://kubernetes.io/docs/user-guide/annotations/))

  Labels are intended for organizational purposes by end users (select the pods
  that match this label query). Annotations enable third-party automation and
  tooling to decorate objects with additional metadata for their own use.

  Source: https://github.com/kubernetes/community/blob/master/contributors/devel/api-conventions.md#metadata
  """
  use Kubernetex.Structure

  defmodule UID do
    @spec parse(any) :: {:ok, String.t()} | {:error, :invalid_uid}
    def parse(binary) when is_binary(binary), do: {:ok, binary}
    def parse(_), do: {:error, :invalid_string}

    def dump(:generated), do: :skip
    def dump(uid), do: {:ok, uid}
  end

  defstructure version: "core/v1" do
    field :name, :string, required: false
    field :namespace, :string, required: false, default: "default"
    field :uid, __MODULE__.UID, required: false, default: :generated

    field :annotations, :map, required: false, default: %{}
    field :creation_timestamp, :timestamp, required: false, default: nil
    field :deletion_timestamp, :timestamp, required: false, default: nil
    field :generation, :non_neg_integer, required: false, default: nil
    field :labels, :map, required: false, default: %{}
    field :resource_version, :string, required: false, default: nil
  end
end
