defmodule PoloWeb.MapLive do
  use PoloWeb, :live_view
  alias PoloWeb.Presence
  alias Phoenix.Socket.Broadcast

  @topic "map:shared"
  @default_view %{lat: 52.212, lng: 0.080, zoom: 15}

  def mount(_params, _session, socket) do
    temp_id =
      if connected?(socket) do
        # Generate unique user ID for this session
        temp_id = "user_#{:crypto.strong_rand_bytes(8) |> Base.encode16()}"

        # Subscribe to shared map topic
        Phoenix.PubSub.subscribe(Polo.PubSub, @topic)

        current_state =
          case Presence.list(@topic) |> Map.values() |> List.first() do
            %{metas: [%{lat: lat, lng: lng, zoom: zoom} | _]} ->
              %{lat: lat, lng: lng, zoom: zoom}
            _ ->
              @default_view
          end

        send(self(), {:map_update, Map.put(current_state, :from_user, "system")})
        temp_id
      else
        nil
      end

    socket = assign(socket,
      view: %{lat: nil, lng: nil, zoom: nil},
      mapbox_token: Application.get_env(:polo, :mapbox_access_token),
      temp_id: temp_id,
      user_id: nil,
      online_users: %{},
      unesco_sites: Polo.UnescoSites.get_sites(),
      show_name_modal: true,
      display_name: ""
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
  def handle_event("random_site", _params, socket) do
    site = Enum.random(socket.assigns.unesco_sites)

    Phoenix.PubSub.broadcast(Polo.PubSub, @topic, {:map_update, %{
      lat: site.latitude,
      lng: site.longitude,
      zoom: 12,
      from_user: "system"
    }})

    {:noreply, socket}
  end
  def handle_event("get_unesco_sites", _params, socket) do
    {:noreply, push_event(socket, "load_unesco_sites", %{sites: socket.assigns.unesco_sites})}
  end
  def handle_event("restore_display_name", %{"name" => name}, socket) do
    {:ok, _} = Presence.track(self(), @topic, socket.assigns.temp_id, %{
      display_name: name,
      joined_at: DateTime.utc_now()
    })

    {:noreply,
      socket
      |> assign(
        show_name_modal: false,
        user_id: socket.assigns.temp_id,
        display_name: name
      )
      |> push_event("js-exec", %{to: "#name_modal", attr: "phx-remove"})
    }
  end
  def handle_event("save_display_name", %{"display_name" => name}, socket) do
    if String.trim(name) != "" do
      {:ok, _} = Presence.track(self(), @topic, socket.assigns.temp_id, %{
        display_name: name,
        joined_at: DateTime.utc_now()
      })

      # Broadcast to JS to save in localStorage
      socket = push_event(socket, "save_display_name", %{name: name})

      {:noreply,
        socket
        |> assign(
          show_name_modal: false,
          user_id: socket.assigns.temp_id,
          display_name: name
        )
        |> push_event("js-exec", %{to: "#name_modal", attr: "phx-remove"})
      }
    else
      {:noreply, socket}
    end

  end

  def handle_info({:map_update, %{from_user: user_id} = params}, socket) do
    # Only update if the change came from another user
    if user_id != socket.assigns.user_id do
      {:noreply, push_event(socket, "update_map", params)}
      else
      {:noreply, socket}
    end
  end
  def handle_info(%Broadcast{event: "presence_diff"} = broadcast, socket) do
    socket = socket
      |> handle_leaves(broadcast.payload.leaves)
      |> handle_joins(broadcast.payload.joins)

    {:noreply, socket}
  end

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user_id, %{metas: [meta | _]}}, socket ->
      assign(socket, :online_users, Map.put(socket.assigns.online_users, user_id, meta))
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user_id, _}, socket ->
      assign(socket, :online_users, Map.delete(socket.assigns.online_users, user_id))
    end)
  end

  defp format_coord(nil), do: ""
  defp format_coord(value) when is_integer(value), do: value
  defp format_coord(value) do
    Float.round(value, 6)
  end
end
