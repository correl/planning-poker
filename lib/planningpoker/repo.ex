defmodule Planningpoker.Repo do
  use Ecto.Repo,
    otp_app: :planningpoker,
    adapter: Ecto.Adapters.Postgres
end
