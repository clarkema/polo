# Polo

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

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

