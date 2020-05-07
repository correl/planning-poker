defmodule PlanningpokerWeb.RoomChannel do
  use Phoenix.Channel
  alias PlanningpokerWeb.Presence

  def join("room:" <> room_id, params, socket) do
    send(self(), :after_join)
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
    {:ok, _} = Presence.track(
      socket,
      "player:#{socket.assigns.player_id}",
      %{
        name: name
      }
    )
    {:noreply, socket}
  end
end
