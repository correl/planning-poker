defmodule PlanningpokerWeb.RoomChannel do
  require Logger
  use Phoenix.Channel
  alias PlanningpokerWeb.Presence
  alias Planningpoker.Db

  def join("room:" <> room_id, params, socket) do
    send(self(), :after_join)
    {:ok, %{channel: room_id, topic: "Planning Poker"},
     socket
     |> assign(:room_id, room_id)}
  end
  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end
  def handle_in("new_profile", %{"name" => name}, socket) do
    Db.save_player(
      socket.assigns.player_id,
      socket.assigns.room_id,
      name)
    {:ok, _} = Presence.track(
      socket,
      socket.assigns.player_id,
      %{}
    )
    {:noreply, socket}
  end
  def handle_in("vote", %{"value" => value}, socket) do
    Db.save_vote(
      socket.assigns.player_id,
      socket.assigns.room_id,
      value
    )
    broadcast!(socket, "vote",
      %{"player" => socket.assigns.player_id,
        "vote" => value})
    {:noreply, socket}
  end
  def handle_in("reset", _, socket) do
    Db.clear_votes(socket.assigns.room_id)
    broadcast!(socket, "reset", %{})
    {:noreply, socket}
  end
  def handle_in(_event, _data, socket) do
    {:noreply, socket}
  end
end
