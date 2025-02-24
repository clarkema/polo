# Polo

Polo is a simple webapp to explore UNESCO world heritage sites collaboratively,
using Phoenix LiveView, Presence, and MapBox.

All connected users share the same viewport.  Any user can navigate, or roll
the dice and visit a random site together.

# Configuration

Configuration is via environment variables.  For the development environment,
the use of a `.env` file is assumed.

The following variables are required in the environment:

  * `MAPBOX_ACCESS_TOKEN`: An access token for MapBox. See [https://docs.mapbox.com/help/getting-started/access-tokens/](https://docs.mapbox.com/help/getting-started/access-tokens/)

# Deployment

The app is configured for deployment on fly.io.  Assuming you have `flyctl`
installed (run `nix-shell` if not and you have Nix available) you can launch a
new instance with `fly launch`.

Don't forget to run `fly secrets set MAPBOX_ACCESS_TOKEN="YOURTOKEN"` to
configure the MapBox token and `fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)`

