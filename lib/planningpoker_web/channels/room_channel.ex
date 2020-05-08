defmodule PlanningpokerWeb.RoomChannel do
  require Logger
  use Phoenix.Channel
  alias PlanningpokerWeb.Presence
  alias Planningpoker.Db

  def join("room:" <> room_id, params, socket) do
    send(self(), :after_join)
    Logger.debug "Proc: #{inspect self()}, Socket: #{inspect socket}"
    {:ok, %{channel: room_id, topic: "Planning Poker"},
     socket
     |> assign(:room_id, room_id)
     |> assign(:player_name, params["playerName"])}
  end
  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end
  def handle_in("new_profile", %{"name" => name}, socket) do
    Db.save_name(socket.assigns.player_id, name)
    {:ok, _} = Presence.track(
      socket,
      socket.assigns.player_id,
      %{}
    )
    {:noreply, socket}
  end
  def handle_in("vote", value, socket) do
    Db.save_vote(
      socket.assigns.player_id,
      socket.assigns.room_id,
      value
    )
    votes = Db.get_votes([socket.assigns.player_id], socket.assigns.room_id)
    {:ok, _} = Presence.update(
      socket,
      socket.assigns.player_id,
      fn x -> x end
    )
    {:noreply, socket}
  end
  def handle_in(_event, _data, socket) do
    {:noreply, socket}
  end
end
