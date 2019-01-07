defmodule CsvUploader.Repo.Migrations.CreateInboundBatchRequests do
  use Ecto.Migration

  def change do
    create table(:inbound_batch_requests, primary_key: false) do
      add :id, :binary_id
      add :batch_request_code, :string, primary_key: true
      add :branch_code, :string
      add :batch_status, :string
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
