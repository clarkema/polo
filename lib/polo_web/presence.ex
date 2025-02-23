defmodule PoloWeb.Presence do
  use Phoenix.Presence,
    otp_app: :polo,
    pubsub_server: Polo.PubSub
end
