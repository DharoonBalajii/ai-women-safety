import { env, isMsg91Configured } from '../config/env.js';
import { logger } from '../lib/logger.js';

const BASE_URL = 'https://control.msg91.com/api/v5/otp';

export interface Msg91Result {
  ok: boolean;
  /// MSG91's own request identifier for this OTP, when available — stored
  /// for audit, never used as a substitute for verification.
  requestId?: string;
  message: string;
}

/// MSG91's v5 OTP endpoints consistently respond with `{ type, message }`
/// ("success" | "error"). Send returns a request id in `message` on success.
interface Msg91ApiResponse {
  type: 'success' | 'error';
  message: string;
}

/// Thin wrapper around MSG91's OTP API. Runs in mock mode (no network call,
/// deterministic success) whenever MSG91_AUTH_KEY/SENDER_ID/TEMPLATE_ID are
/// unset, so the auth flow is fully testable before real credentials exist —
/// same pattern as the app's Sarvam AI integration.
export class Msg91Service {
  get isConfigured(): boolean {
    return isMsg91Configured;
  }

  async sendOtp(phoneNumber: string): Promise<Msg91Result> {
    if (!this.isConfigured) {
      logger.info({ phoneNumber }, '[msg91:mock] send-otp');
      return { ok: true, requestId: 'mock-request-id', message: 'Mock OTP sent' };
    }

    const url = new URL(BASE_URL);
    url.searchParams.set('template_id', env.MSG91_OTP_TEMPLATE_ID);
    url.searchParams.set('mobile', phoneNumber);
    url.searchParams.set('otp_length', '6');
    url.searchParams.set('otp_expiry', '10');

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { authkey: env.MSG91_AUTH_KEY, 'Content-Type': 'application/json' },
      });
      const body = (await response.json()) as Msg91ApiResponse;
      logger.info({ phoneNumber, type: body.type }, 'msg91:send-otp');
      return { ok: body.type === 'success', requestId: body.message, message: body.message };
    } catch (error) {
      logger.error({ err: error, phoneNumber }, 'msg91:send-otp failed');
      return { ok: false, message: 'MSG91 request failed' };
    }
  }

  async verifyOtp(phoneNumber: string, code: string): Promise<Msg91Result> {
    if (!this.isConfigured) {
      // Deterministic mock: accept "000000" so the app is demoable end to end.
      const ok = code === '000000';
      logger.info({ phoneNumber, ok }, '[msg91:mock] verify-otp');
      return { ok, message: ok ? 'Mock OTP verified' : 'Mock OTP mismatch (use 000000)' };
    }

    const url = new URL(`${BASE_URL}/verify`);
    url.searchParams.set('mobile', phoneNumber);
    url.searchParams.set('otp', code);

    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: { authkey: env.MSG91_AUTH_KEY },
      });
      const body = (await response.json()) as Msg91ApiResponse;
      logger.info({ phoneNumber, type: body.type }, 'msg91:verify-otp');
      return { ok: body.type === 'success', message: body.message };
    } catch (error) {
      logger.error({ err: error, phoneNumber }, 'msg91:verify-otp failed');
      return { ok: false, message: 'MSG91 request failed' };
    }
  }
}

export const msg91Service = new Msg91Service();
