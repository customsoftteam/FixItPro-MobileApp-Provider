const axios = require('axios');

/**
 * Reverse Geocode: Convert latitude/longitude to human-readable address
 * Uses OpenStreetMap Nominatim API (free, no authentication needed)
 * @param {number} latitude
 * @param {number} longitude
 * @returns {Promise<string>} - Readable address text
 */
const reverseGeocode = async (latitude, longitude) => {
  try {
    if (!latitude || !longitude) {
      return 'Location not available';
    }

    const response = await axios.get('https://nominatim.openstreetmap.org/reverse', {
      params: {
        format: 'json',
        lat: latitude,
        lon: longitude,
        zoom: 18,
        addressdetails: 1,
      },
      timeout: 5000,
      headers: {
        'User-Agent': 'FixItPro-ServiceProvider/1.0',
      },
    });

    // Extract the full address from the response
    const address = response.data?.address || {};
    const displayName = response.data?.display_name;

    // Build a readable address string
    if (displayName) {
      // Return the display name which includes full address
      return displayName;
    }

    return 'Location not found';
  } catch (error) {
    console.error('Geocoding error:', error.message);
    // Fallback to coordinate display if API fails
    return `Coordinates: ${latitude.toFixed(4)}°, ${longitude.toFixed(4)}°`;
  }
};

module.exports = {
  reverseGeocode,
};
