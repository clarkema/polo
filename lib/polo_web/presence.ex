defmodule PoloWeb.Presence do
  @moduledoc "Phoenix.Presence module for PoloWeb"
  use Phoenix.Presence,
    otp_app: :polo,
    pubsub_server: Polo.PubSub
end
