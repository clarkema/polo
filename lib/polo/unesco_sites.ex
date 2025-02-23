defmodule Polo.UnescoSites do
  @moduledoc """
  This module provide a shared database of UNESCO World Heritage Sites data.

  Data is loaded from an XML file located in the `priv` directory.

  To use, add `Polo.UnescoSites` to your supervision tree.

  ## Functions

    * `get_sites/0` - Retrieves the list of UNESCO sites.

  ## XML Structure

  The XML file is expected to have the following structure for each site:

  ```xml
  <row>
    <id_number>1</id_number>
    <site>Site Name</site>
    <latitude>12.3456</latitude>
    <longitude>65.4321</longitude>
    <short_description>Description of the site</short_description>
  </row>
  ```
  """

  use GenServer
  require Logger
  import SweetXml

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    sites = load_sites()
    {:ok, sites}
  end

  @doc """
  Retrieves the list of UNESCO sites.  Each site is a map with the following contents:

  * `id` - The site's unique identifier
  * `name` - The site's name
  * `latitude` - The site's latitude
  * `longitude` - The site's longitude
  * `desc` - A short description of the site
  """
  def get_sites do
    GenServer.call(__MODULE__, :get_sites)
  end

  def handle_call(:get_sites, _from, sites) do
    {:reply, sites, sites}
  end

  defp load_sites do
    priv_dir = :code.priv_dir(:polo)
    path = Path.join(priv_dir, "unesco_sites.xml")

    case File.read(path) do
      {:ok, body} ->

        sites =
          body
          |> SweetXml.xpath(~x"//row"l,
            id: ~x"./id_number/text()"s,
            name: ~x"./site/text()"s,
            latitude: ~x"./latitude/text()"s,
            longitude: ~x"./longitude/text()"s,
            desc: ~x"./short_description/text()"s)
          |> Enum.map(fn site ->
            %{
              id: String.to_integer(site.id),
              name: site.name,
              latitude: parse_coordinates(site.latitude),
              longitude: parse_coordinates(site.longitude),
              desc: site.desc
            }
          end)

        sites
      {:error, reason} ->
        Logger.error("Failed to read UNESCO sites file: #{inspect(reason)}")
        []
    end
  end

  def parse_coordinates(coord_str) do
    case Float.parse(coord_str) do
      {num, _} -> num
      :error -> nil
    end
  end
end
