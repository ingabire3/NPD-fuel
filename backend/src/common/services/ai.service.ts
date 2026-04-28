import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private readonly baseUrl: string;
  private readonly apiKey: string;

  constructor(
    private http: HttpService,
    private config: ConfigService,
  ) {
    this.baseUrl = config.get('aiService.url');
    this.apiKey = config.get('aiService.key');
  }

  private get headers() {
    return { 'X-Internal-Key': this.apiKey };
  }

  async extractReceiptOcr(imageUrl: string) {
    try {
      const { data } = await firstValueFrom(
        this.http.post(
          `${this.baseUrl}/ocr/receipt`,
          { imageUrl },
          { headers: this.headers },
        ),
      );
      return data;
    } catch (err) {
      this.logger.warn(`OCR receipt failed: ${err.message}`);
      return { data: null, confidence: null };
    }
  }

  async extractOdometerOcr(imageUrl: string) {
    try {
      const { data } = await firstValueFrom(
        this.http.get(`${this.baseUrl}/ocr/odometer`, {
          headers: this.headers,
          params: { imageUrl },
        }),
      );
      return data;
    } catch (err) {
      this.logger.warn(`OCR odometer failed: ${err.message}`);
      return { reading: null, confidence: null };
    }
  }
}
