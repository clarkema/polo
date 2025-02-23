defmodule PoloWeb.MapLive do
  use PoloWeb, :live_view
  alias PoloWeb.Presence
  alias Phoenix.Socket.Broadcast

  @topic "map:shared"
  @default_view %{lat: 52.212, lng: 0.080, zoom: 15}

  def mount(_params, _session, socket) do
    user_id =
      if connected?(socket) do
        # Generate unique user ID for this session
        user_id = "user_#{:crypto.strong_rand_bytes(8) |> Base.encode16()}"

        # Subscribe to shared map topic
        Phoenix.PubSub.subscribe(Polo.PubSub, @topic)

        current_state =
          case Presence.list(@topic) |> Map.values() |> List.first() do
            %{metas: [%{lat: lat, lng: lng, zoom: zoom} | _]} ->
              %{lat: lat, lng: lng, zoom: zoom}
            _ ->
              @default_view
          end

        # Track this users's presence
        {:ok, _} = Presence.track(self(), @topic, user_id, Map.merge(current_state,  %{
          joined_at: DateTime.utc_now(),
        }))

        send(self(), {:map_update, Map.put(current_state, :from_user, "system")})
        user_id
      else
        nil
      end

    socket = assign(socket,
      view: %{lat: nil, lng: nil, zoom: nil},
      mapbox_token: Application.get_env(:polo, :mapbox_access_token),
      user_id: user_id
    )

    {:ok, socket, layout: false}
  end

  def handle_event("view_updated", %{"lat" => lat, "lng" => lng, "zoom" => zoom}, socket) do
    # Update presence metadata with new view
    Presence.update(self(), @topic, socket.assigns.user_id, fn meta ->
      Map.merge(meta, %{lat: lat, lng: lng, zoom: zoom})
    end)

    # Broadcast update to clients
    Phoenix.PubSub.broadcast(Polo.PubSub, @topic, {:map_update, %{
      lat: lat,
      lng: lng,
      zoom: zoom,
      from_user: socket.assigns.user_id
    }})

    {:noreply, assign(socket, view: %{lat: lat, lng: lng, zoom: zoom})}
  end

  def handle_info({:map_update, %{from_user: user_id} = params}, socket) do
    # Only update if the change came from another user
    if user_id != socket.assigns.user_id do
      {:noreply, push_event(socket, "update_map", params)}
      else
      {:noreply, socket}
    end
  end
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply, socket}
  end

  defp format_coord(nil), do: ""
  defp format_coord(value) do
    Float.round(value, 6)
  end
end
