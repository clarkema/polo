import mapboxgl from "mapbox-gl";

export const MapHook = {
  mounted() {
	mapboxgl.accessToken = this.el.dataset.mapboxToken;

    // Track animation state to prevent feedback loops
    this.isAnimating = false;

    this.map = new mapboxgl.Map({
      container: this.el,
      style: 'mapbox://styles/mapbox/streets-v9',
      zoom: 5,
      center: [-0.080, 52.212]
    });

    this.map.addControl(new mapboxgl.NavigationControl());

    this.map.on('style.load', () => {
        this.map.setFog({}); // Set the default atmosphere style
    });

    // Set up event handlers
    this.map.on('moveend', () => {
      // Only send updates if we're not currently processing a received
      // update
      if (!this.isAnimating) {
        const center = this.map.getCenter();
        const zoom = this.map.getZoom();

        // Push event to LiveView
        this.pushEvent("view_updated", {
          lat: center.lat,
          lng: center.lng,
          zoom: zoom
        });
      }
    });

    this.handleEvent("update_map", ({lat, lng, zoom, from_user}) => {
      // Skip animation for initial system update
      if (from_user === "system") {
        this.map.setCenter([lng, lat]);
        this.map.setZoom(zoom);
        return;
      }

      this.isAnimating = true;

      this.map.easeTo({
          center: [lng, lat],
          zoom: zoom,
          duration: 1000 // smooth transition over 1 second
      });

      // Reset animation flag after animation completes
      setTimeout(() => {
          this.isAnimating = false;
      }, 1100); // Slighly longer than animation to ensure completion
    });
  },

  destroyed() {
    if (this.map) {
      this.map.remove();
    }
  }
}
