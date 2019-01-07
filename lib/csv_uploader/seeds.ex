alias CsvUploader.Repo
alias CsvUploader.Uploader
# alias CsvUploader.Request.InboundItemRequest
alias CsvUploader.DataUploader.InboundItemRequest
alias CsvUploader.DataUploader.InboundBatchRequest
alias CsvUploader.DataUploader.OutboundBatchRequest

defmodule CsvUploader.Seeds do
  require Logger
  use Ecto.Schema

  def store_request(rows, name) do
    time = Uploader.current_time()
    IO.puts("#{time}: Inserting/updating row from #{name}....")
    Logger.info("\n#{time}: Inserting/updating row from #{name}....", result: 1)

    result = rows
      |> Enum.with_index()
      |> Enum.reduce(Ecto.Multi.new(), fn ({changeset, index}, multi) ->
        cs = case Repo.get(InboundItemRequest, changeset.changes[:item_key]) do
          nil  ->
            IO.puts "#{time}: Row does not exist yet. Inserting..."
            Logger.info("\n#{time}: Row does not exist yet. Inserting...", result: 1)
            changeset
          inbound_item_requests ->
            IO.puts "#{time}: Row does exist. Updating row..."
            Logger.info("\n#{time}: Row does exist. Updating row...", result: 1)
            inbound_item_requests
        end
        |> InboundItemRequest.changeset(changeset.changes)
         Ecto.Multi.insert_or_update(multi, Integer.to_string(index), cs)
      end)
      |> Repo.transaction

      case result do
        {:ok, batch_req_result }  ->
          IO.puts "#{time}: All rows from #{name} successfully uploaded."
          Logger.info("\n#{time}: All rows from #{name} successfully uploaded.", result: 1)
        {:error, _, %{errors: errors}, _} ->
          Enum.map(errors, &handle_error(&1, name))
          :error
      end
  end

  def store_acknowledgement(rows, name) do
    time = Uploader.current_time()
    IO.puts("#{time}: Inserting/updating row from #{name}....")
    Logger.info("\n#{time}: Inserting/updating row from #{name}....", result: 1)

    batch_table = String.slice(name, 6..6)

    case batch_table do
      "I" ->
        IO.puts("#{time}: Inbound ack file detected. Saving data to InboundBatchRequest table...")
        Logger.info("\n#{time}: Inbound ack file detected. Saving data to InboundBatchRequest table...", result: 1)
        do_store_acknowledgement_inbound(rows, time, name)
      "O" ->
        IO.puts("#{time}: Outbound ack file detected.  Saving data to OutboundBatchRequest table...")
        Logger.info("\n#{time}: Outbound ack file detected.  Saving data to OutboundBatchRequest table...", result: 1)
        do_store_acknowledgement_outbound(rows, time, name)
    end
  end

  def do_store_acknowledgement_inbound(rows, time, name) do
    result = rows
      |> Enum.with_index()
      |> Enum.reduce(Ecto.Multi.new(), fn ({changeset, index}, multi) ->
        cs = case Repo.get(InboundBatchRequest, changeset.changes[:batch_request_code]) do
          nil  ->
            IO.puts "#{time}: Row does not exist. Inserting..."
            Logger.info("\n#{time}: Row does not exist yet. Inserting...", result: 1)
            changeset
          inbound_item_requests ->
            IO.puts "#{time}: Row does exist. Updating row..."
            Logger.info("\n#{time}: Row does exist. Updating row...", result: 1)
            inbound_item_requests
        end
        |> InboundBatchRequest.changeset(changeset.changes)
         Ecto.Multi.insert_or_update(multi, Integer.to_string(index), cs)
      end)
      |> Repo.transaction

      case result do
        {:ok, ack_result }  ->
          IO.puts "#{time}: All rows from #{name} successfully uploaded."
          Logger.info("\n#{time}: All rows from #{name} successfully uploaded.", result: 1)
        {:error, _, %{errors: errors}, _} ->
          Enum.map(errors, &handle_error(&1, name))
          :error
      end
  end

  def do_store_acknowledgement_outbound(rows, time, name) do
    result = rows
      |> Enum.with_index()
      |> Enum.reduce(Ecto.Multi.new(), fn ({changeset, index}, multi) ->
        cs = case Repo.get(OutboundBatchRequest, changeset.changes[:batch_request_code]) do
          nil  ->
            IO.puts "#{time}: Row does not exist. Inserting..."
            Logger.info("\n#{time}: Row does not exist yet. Inserting...", result: 1)
            changeset
          outbound_item_requests ->
            IO.puts "#{time}: Row does exist. Updating row..."
            Logger.info("\n#{time}: Row does exist. Updating row...", result: 1)
            outbound_item_requests
        end
        |> OutboundBatchRequest.changeset(changeset.changes)
         Ecto.Multi.insert_or_update(multi, Integer.to_string(index), cs)
      end)
      |> Repo.transaction

      case result do
        {:ok, ack_result }  ->
          IO.puts "#{time}: All rows from #{name} successfully uploaded."
          Logger.info("\n#{time}: All rows from #{name} successfully uploaded.", result: 1)
        {:error, _, %{errors: errors}, _} ->
          Enum.map(errors, &handle_error(&1, name))
          :error
      end
  end

  defp handle_error({:itemName, {message, _}}, name) do
    time = Uploader.current_time()
      IO.puts "#{time}: One of the rows from #{name} failed to insert [error:  #{message}]. Cancelling the upload..."
      Logger.info("\n#{time}: One of the rows from #{name} failed to insert [error:  #{message}]. Cancelling the upload...", result: 1)
  end

  defp handle_error({_, {message, _}}, name) do
    time = Uploader.current_time()
      IO.puts "#{time}: One of the rows from #{name} failed to insert [error:  #{message}]. Cancelling the upload..."
      Logger.info("\n#{time}: One of the rows from #{name} failed to insert [error:  #{message}]. Cancelling the upload...", result: 1)
  end

end
