# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :csv_uploader,
  ecto_repos: [CsvUploader.Repo]

# Configures the endpoint
config :csv_uploader, CsvUploaderWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "96D9qTkL1lJJFucnPWqsnuV5HWfniGDhfhVO8eEQcLObVgbja16nqSaF9w/cBlxM",
  render_errors: [view: CsvUploaderWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: CsvUploader.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :logger,
  backends: [{LoggerFileBackend, :result_log}]

config :logger, :result_log,
  path: "../../mhqdata/mdu/logs/result_log.log",
  level: :debug,
  metadata_filter: [result: 1]

config :csv_uploader,
  # data_folder: "/home/juliusaviquivil/mhqdatauploader/databases/data/",
  # fail_folder: "/home/juliusaviquivil/mhqdatauploader/databases/fail/",
  # success_folder: "/home/juliusaviquivil/mhqdatauploader/databases/success/",
  # ack_folder: "/home/juliusaviquivil/mhqdatauploader/databases/logs/"
  data_folder: "../../mhqdata/mdu/data/",
  fail_folder: "../../mhqdata/mdu/fail/",
  success_folder: "../../mhqdata/mdu/success/",
  ack_folder: "../../mhqdata/mfc/outbound/",
  interval: 10000
  # data_folder: "",
  # fail_folder: "",
  # success_folder: "",
  # logs_folder: ""

config :csv_uploader, CsvUploader.Repo,
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: false

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
