import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Client, TravelMode, UnitSystem } from '@googlemaps/google-maps-services-js';

@Injectable()
export class GoogleMapsService {
  private readonly client = new Client({});
  private readonly logger = new Logger(GoogleMapsService.name);

  constructor(private config: ConfigService) {}

  async getDistanceKm(
    originLat: number,
    originLng: number,
    destLat: number,
    destLng: number,
  ): Promise<number | null> {
    const apiKey = this.config.get<string>('googleMaps.apiKey');
    if (!apiKey) {
      this.logger.warn('GOOGLE_MAPS_API_KEY not configured — skipping distance fetch');
      return null;
    }

    try {
      const res = await this.client.distancematrix({
        params: {
          origins: [{ lat: originLat, lng: originLng }],
          destinations: [{ lat: destLat, lng: destLng }],
          mode: TravelMode.driving,
          units: UnitSystem.metric,
          key: apiKey,
        },
      });

      const element = res.data.rows[0]?.elements[0];
      if (!element || element.status !== 'OK') {
        this.logger.warn(`Distance Matrix returned status: ${element?.status}`);
        return null;
      }

      return element.distance.value / 1000;
    } catch (err) {
      this.logger.error('Google Maps API call failed', (err as Error).message);
      return null;
    }
  }
}
