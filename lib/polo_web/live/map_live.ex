defmodule PoloWeb.MapLive do
  use PoloWeb, :live_view

  def mount(_params, _session, socket) do
    socket = assign(socket,
      view: %{lat: nil, lng: nil, zoom: nil},
      mapbox_token: Application.get_env(:polo, :mapbox_access_token)
    )

    {:ok, socket, layout: false}
  end

  def handle_event("view_updated", %{"lat" => lat, "lng" => lng, "zoom" => zoom}, socket) do
    socket = assign(socket, view: %{lat: lat, lng: lng, zoom: zoom})

    {:noreply, socket}
  end

  defp format_coord(nil), do: ""
  defp format_coord(value) do
    Float.round(value, 6)
  end
end
