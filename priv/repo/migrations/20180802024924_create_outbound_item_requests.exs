defmodule CsvUploader.Repo.Migrations.CreateOutboundItemRequests do
  use Ecto.Migration

  def change do
    create table(:outbound_item_requests, primary_key: false) do
      add :id, :binary_id
      add :item_request_code, :string
      add :item_key, :string, primary_key: true
      add :item_name, :string
      add :item_qty, :decimal
      add :item_status, :string
      add :item_unit_mes, :map
      add :batch_request_code, :string
      add :created_by, :string
      add :modified_by, :string
      add :created_date, :utc_datetime
      add :modified_date, :utc_datetime
      add :requestor, :string
      add :requestee, :string

      timestamps()
    end

  end
end
