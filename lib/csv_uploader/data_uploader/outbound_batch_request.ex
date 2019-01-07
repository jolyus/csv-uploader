defmodule CsvUploader.DataUploader.OutboundBatchRequest do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:batch_request_code, :string, autogenerate: false}
  schema "outbound_batch_requests" do
    field :batch_status, :string
    field :branch_code, :string
    field :created_by, :string
    field :created_date, :utc_datetime
    field :modified_by, :string
    field :modified_date, :utc_datetime
    field :requestor, :string
    field :requestee, :string

    timestamps()
  end

  @doc false
  def changeset(outbound_batch_request, attrs) do
    outbound_batch_request
    |> cast(attrs, [:batch_request_code, :branch_code, :batch_status, :created_by, :modified_by, :created_date, :modified_date, :requestor, :requestee])
    # |> cast(attrs, [])
    # |> validate_required([])
  end
end
