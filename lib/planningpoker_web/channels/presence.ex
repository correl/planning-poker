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

  def fetch("room:" <> room, entries) do
    players =
      entries
      |> Map.keys()
      |> Db.get_players(room)
      |> Enum.into(%{}, fn {{u, _r}, v} -> {u, v} end)
    votes =
      entries
      |> Map.keys()
      |> Db.get_votes(room)
      |> Enum.into(%{}, fn {{u, _r}, v} -> {u, v} end)

    for {key, %{metas: metas}} <- entries, into: %{} do
      {key, %{metas: metas,
              name: players[key],
              vote: Map.get(votes, key)}}
    end
  end
  def fetch(_topic, entries), do: entries
end
