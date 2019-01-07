defmodule CsvUploaderWeb.Router do
  use CsvUploaderWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", CsvUploaderWeb do
    pipe_through :api
  end
end
