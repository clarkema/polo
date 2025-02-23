import mapboxgl from '../../vendor/mapbox-gl';

export const MapHook = {
  mounted() {
	mapboxgl.accessToken = this.el.dataset.mapboxToken;

    this.map = new mapboxgl.Map({
      container: this.el,
      style: 'mapbox://styles/mapbox/streets-v9',
      zoom: 5,
      center: [-2, 54]
    });

    this.map.addControl(new mapboxgl.NavigationControl());

    this.map.on('style.load', () => {
        this.map.setFog({}); // Set the default atmosphere style
    });

    // Set up event handlers
    this.map.on('moveend', () => {
      const center = this.map.getCenter();
      const zoom = this.map.getZoom();

      // Push event to LiveView
      this.pushEvent("view_updated", {
        lat: center.lat,
        lng: center.lng,
        zoom: zoom
      });
    });
  },

  destroyed() {
    if (this.map) {
      this.map.remove();
    }
  }
}
