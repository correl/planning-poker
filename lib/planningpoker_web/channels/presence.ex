defmodule PlanningpokerWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](http://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence, otp_app: :planningpoker,
                        pubsub_server: Planningpoker.PubSub
  require Logger
  alias Planningpoker.Db

  def fetch(_topic, entries) do
    users =
      entries
      |> Map.keys()
      |> Db.get_users()
      |> Enum.into(%{})

    for {key, %{metas: metas}} <- entries, into: %{} do
      {key, %{metas: metas, name: users[key]}}
    end
  end
end
