defmodule CsvUploader.DataUploader.OutboundItemRequest do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:item_key, :string, autogenerate: false}
  schema "outbound_item_requests" do
    field :batch_request_code, :string
    field :created_by, :string
    field :created_date, :utc_datetime
    field :item_name, :string
    field :item_qty, :decimal
    field :item_status, :string
    field :item_unit_mes, :map
    field :item_request_code, :string
    field :modified_by, :string
    field :modified_date, :utc_datetime
    field :requestor, :string
    field :requestee, :string

    timestamps()
  end

  @doc false
  def changeset(inbound_item_request, attrs) do
    inbound_item_request
    |> cast(attrs, [:item_key, :item_request_code, :item_name, :item_qty, :item_status, :item_unit_mes, :batch_request_code, :created_by, :modified_by, :created_date, :modified_date, :requestor, :requestee])
    # |> cast(attrs, [])
    # |> validate_required([])
  end
end
