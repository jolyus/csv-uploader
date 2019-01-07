alias CsvUploader.Repo
alias CsvUploader.Uploader
alias CsvUploader.DataUploader.InboundItemRequest
alias CsvUploader.DataUploader.InboundBatchRequest
alias CsvUploader.DataUploader.OutboundBatchRequest

defmodule CsvUploader.Uploader do
  use GenServer
  require Logger

  def process_value(value) do
    elem(value, 1)
  end

  def convert_to_boolean(value) do
    if value === 'f' do
      true
    else
      false
    end
  end

  def convert_to_integer(value) do
    IO.inspect(Integer.parse(value))
  end

  def convert_to_date(value) do
    IO.inspect(Ecto.Date.cast(value))
  end

  def convert_to_map(value) do
    Regex.replace(~r/([a-z0-9]+):/, value, "\"\\1\":")
    |> String.replace("'", "\"")
    |> Poison.decode!()
  end

  def start_link do
    GenServer.start_link(__MODULE__, [:ok], name: __MODULE__)
  end

  def init(state) do
    schedule_work()
    {:ok, state}
  end

  def handle_info(:check_folder, state) do
    check_folder()
    schedule_work()
    {:noreply, state}
  end

  def schedule_work() do
    Process.send_after(self(), :check_folder, Application.get_env(:csv_uploader, :interval))
  end

  def current_time do
    time = Time.utc_now()
    Time.truncate(time, :second)
  end

  def check_folder do
    data_folder = "#{Application.get_env(:csv_uploader, :data_folder)}"
    time = Uploader.current_time()

    try do
      CsvUploader.Uploader.check_dir()

      x =
        Path.wildcard("#{data_folder}*.{csv}")
        |> Enum.map(&Path.basename/1)

      # Enum.each(x, &get_details/1)
      Enum.each(x, &uploader/1)
    rescue
      err in RuntimeError ->
        IO.puts("#{time}, Error:" <> err.message)
        Logger.error("#{time}, Error:" <> err.message <> "", result: 1)
    end
  end

  def get_details(file) do
    type = String.slice(file, 0..2)
    branch_code = String.slice(file, 3..5)
    batch_req_code = String.slice(file, 6..18)
    date = String.slice(file, 19..28)

    file_details = %{
      "type" => type,
      "branch_code" => branch_code,
      "batch_req_code" => batch_req_code,
      "date" => date
    }

    file_details
  end

  def get_file_type(file) do
    String.slice(file, 0..2)
  end

  def check_dir do
    time = Uploader.current_time()
    data_folder = "#{Application.get_env(:csv_uploader, :data_folder)}"
    fail_folder = "#{Application.get_env(:csv_uploader, :fail_folder)}"
    success_folder = "#{Application.get_env(:csv_uploader, :success_folder)}"
    logs_folder = "#{Application.get_env(:csv_uploader, :logs_folder)}"

    # IO.puts data_folder
    # IO.puts fail_folder
    # IO.puts success_folder
    # IO.puts logs_folder

    cond do
      File.exists?(data_folder) ->
        IO.puts("#{time}: Directory exists. Proceeding..")
        File.mkdir_p(fail_folder)
        File.mkdir_p(success_folder)
        File.mkdir_p(logs_folder)

      true ->
        IO.puts("#{time}: Directory doesn't exist, creating folders...")
        File.mkdir_p(data_folder)
        File.mkdir_p(fail_folder)
        File.mkdir_p(success_folder)
        File.mkdir_p(logs_folder)
    end
  end

  def rename_success(name) do
    time = Uploader.current_time()
    data_folder = "#{Application.get_env(:csv_uploader, :data_folder)}"
    success_folder = "#{Application.get_env(:csv_uploader, :success_folder)}"

    File.rename("#{data_folder}#{name}", "#{success_folder}#{name}")
    IO.puts("#{time}: Copied file #{name} to the success directory.")
    Logger.info("\n#{time}: Copied file #{name} to the success directory.")
  end

  def rename_fail(name) do
    time = Uploader.current_time()
    data_folder = "#{Application.get_env(:csv_uploader, :data_folder)}"
    fail_folder = "#{Application.get_env(:csv_uploader, :fail_folder)}"

    File.rename("#{data_folder}#{name}", "#{fail_folder}#{name}")
    IO.puts("#{time}: Copied file #{name} to the fail directory.")
    Logger.info("\n#{time}: Copied file #{name} to the fail directory.")
  end

  def uploader(name) do
    time = Uploader.current_time()
    data_folder = "#{Application.get_env(:csv_uploader, :data_folder)}"
    file_details = get_details(name)
    file_type = file_details["type"]

    IO.puts("#{time}: Starting to read and upload the file: #{name}")
    Logger.info("\n#{time}: Starting to read and upload the file: #{name}.", result: 1)

    result =
      File.stream!(Path.expand("#{data_folder}#{name}"))
      |> Stream.drop(1)
      |> decode_file(name)

    case result do
      :ok ->
        CsvUploader.Uploader.rename_success(name)
        IO.puts("#{time}: Uploading #{name} complete...")
        Logger.info("\n#{time}: Uploading #{name} complete...", result: 1)

        case file_type do
          "REQ" ->
            create_update_batch(name)

          "ACK" ->
            IO.puts("")
        end

      # create_acknowledgement(name)
      :error ->
        CsvUploader.Uploader.rename_fail(name)
        IO.puts("#{time}: Uploading #{name} failed...")
        Logger.info("\n#{time}: #{name} failed to upload", result: 1)
    end
  end

  def create_acknowledgement(info) do
    timestamp = NaiveDateTime.to_iso8601(DateTime.utc_now(), :basic)
    log_time = Uploader.current_time()
    ack_folder = "#{Application.get_env(:csv_uploader, :ack_folder)}"

    IO.puts("#{log_time}: Creating acknowledgement file...")
    Logger.info("\n#{log_time}: Creating acknowledgement file...", result: 1)

    file_info = get_details(info)

    file =
      File.open!("#{ack_folder}ACK#{file_info["batch_request_code"]}#{timestamp}.csv", [
        :write,
        :utf8
      ])

    ack_details = [
      %{"batch_request_code" => file_info["batch_req_code"], "batch_status" => "Received"}
    ]

    ack_details
    |> CSV.Encoding.Encoder.encode(headers: true)
    |> Enum.to_list()
    |> Enum.each(&IO.write(file, &1))
  end

  def create_update_batch(info) do
    file_details = get_details(info)
    time = Uploader.current_time()
    # IO.inspect file_details

    batch_details = %{
      "branch_code" => file_details["branch_code"],
      "batch_request_code" => "#{file_details["branch_code"]}#{file_details["batch_req_code"]}",
      "batch_status" => "Received"
    }

    changeset = InboundBatchRequest.changeset(%InboundBatchRequest{}, batch_details)

    result =
      case Repo.get(InboundBatchRequest, changeset.changes[:batch_request_code]) do
        nil ->
          IO.puts("#{time}: Batch request doesn't exist. Inserting batch request...")

          Logger.info(
            "\n#{time}: Batch request doesn't exist. Inserting batch request...",
            result: 1
          )

          changeset

        inbound_batch_requests ->
          IO.puts("#{time}: Batch request exists. Updating batch request...")
          Logger.info("\n#{time}: Batch request exists. Updating batch request...", result: 1)
          inbound_batch_requests
      end
      |> InboundBatchRequest.changeset(changeset.changes)
      |> Repo.insert_or_update()

    case result do
      {:ok, _} ->
        IO.puts("#{time}: Batch Request successfully inserted/updated...")
        Logger.info("\n#{time}: Batch Request successfully inserted/updated...", result: 1)

      # create_acknowledgement(info)

      {:error, _} ->
        IO.puts("#{time}: Error inserting/updating the batch request...")
        Logger.error("\n#{time}: Error inserting/updating the batch request...", result: 1)
    end
  end

  def decode_file(contents, filename) do
    time = Uploader.current_time()

    file_details = get_details(filename)
    file_type = file_details["type"]
    batch_table = String.slice(filename, 6..6)

    case file_type do
      "REQ" ->
        IO.puts("#{time}: Decoding request file: #{filename}....")
        Logger.info("\n#{time}: Decoding request file: #{filename}....", result: 1)

        decoded =
          contents
          |> CSV.decode(
            headers: [
              :batch_request_code,
              :item_key,
              :item_name,
              :item_qty,
              :item_request_code,
              :item_status,
              :requestor,
              :requestee
            ]
          )

      "ACK" ->
        IO.puts("#{time}: Decoding acknowledgement file: #{filename}....")
        Logger.info("\n#{time}: Decoding acknowledgement file: #{filename}....", result: 1)
        decoded = contents |> CSV.decode(headers: [:batch_request_code, :batch_status, :requestor, :requestee])
    end

    count = Enum.count(decoded)
    rows = Enum.take(decoded, count)
    result = check_if_decoded(rows)

    case result do
      :error ->
        IO.puts("\n#{time}: Error decoding file:  #{filename}...")
        Logger.info("\n#{time}: Error decoding file: #{filename}...", result: 1)
        :error

      :ok ->
        IO.puts("\n#{time}: Successfully decoded the file:  #{filename}...")
        Logger.info("\n#{time}: Successfully decoded the file: #{filename}...", result: 1)

        case file_type do
          "REQ" ->
            rows
            |> Enum.map(&InboundItemRequest.changeset(%InboundItemRequest{}, process_value(&1)))
            |> CsvUploader.Seeds.store_request(filename)

          "ACK" ->
            case batch_table do
              "I" ->
                rows
                |> Enum.map(
                  &InboundBatchRequest.changeset(%InboundBatchRequest{}, process_value(&1))
                )
                |> CsvUploader.Seeds.store_acknowledgement(filename)

              "O" ->
                rows
                |> Enum.map(
                  &OutboundBatchRequest.changeset(%OutboundBatchRequest{}, process_value(&1))
                )
                |> CsvUploader.Seeds.store_acknowledgement(filename)
            end
        end
    end

    # |> Enum.into(transfers)
    # |> IO.inspect

    # |> Enum.map(&InboundItemRequest.changeset(%InboundItemRequest{}, process_value_products(&1)))
    # |> CsvUploader.Seeds.store_it(filename)
    # |> Enum.map(&Product.changeset(%Product{}, process_value_products(&1)))
    # |> CsvUploader.Seeds.store_it(filename)
  end

  def check_if_decoded(content) do
    test =
      Enum.map(content, fn row ->
        cond do
          elem(row, 0) === :error ->
            "error"

          true ->
            "ok"
        end
      end)

    result =
      case Enum.member?(test, "error") do
        true ->
          :error

        false ->
          :ok
      end

    result
  end
end
