import { env } from '../config/env.js';
import { logger } from '../lib/logger.js';

const STT_URL = 'https://api.sarvam.ai/speech-to-text';
const CHAT_URL = 'https://api.sarvam.ai/v1/chat/completions';

const THREAT_TYPES = ['following', 'threatened', 'medical', 'accident', 'harassment', 'unknown'] as const;
export type ThreatType = (typeof THREAT_TYPES)[number];

const THREAT_LEVELS = ['none', 'caution', 'danger'] as const;
export type ThreatLevel = (typeof THREAT_LEVELS)[number];

export interface AnalysisResult {
  analyzed: boolean;
  transcript: string;
  detectedLanguage: string | null;
  threatType: ThreatType | null;
  summary: string;
}

export interface AmbientResult {
  analyzed: boolean;
  transcript: string;
  level: ThreatLevel | null;
  reason: string;
}

const REPORT_SYSTEM_PROMPT = `You are an emergency triage assistant for a women's safety app. The
transcript is spoken by the person in the possible emergency themselves,
in any language or mixed languages (e.g. Hindi-English, Tamil-English
code-switching) — understand the meaning regardless of language. Respond
with ONLY a compact JSON object, no prose, in this exact shape:
{"threat_type": "following|threatened|medical|accident|harassment|unknown",
 "summary": "one short sentence describing what is happening, in English"}

Category definitions:
- "following": being pursued, stalked, or trailed by someone.
- "threatened": someone is directly threatening violence, harm, or using
  a weapon against the speaker right now.
- "accident": a vehicle collision, fire, or structural incident (e.g. a
  building collapse). Use this whenever such an incident is explicitly
  mentioned, even if the report also mentions an injury — accident
  response already includes medical aid, so the incident itself decides
  the category.
- "medical": an injury or health crisis with no vehicle collision, fire,
  or structural incident mentioned — a fall, a broken bone, sudden
  illness, difficulty breathing, bleeding on its own.
- "harassment": unwanted contact, touching, or verbal/sexual abuse
  without an immediate physical threat of violence.
- "unknown": none of the above clearly fit, or the situation is unclear.`;

const AMBIENT_SYSTEM_PROMPT = `You are a covert threat-detection assistant. A phone belonging to a
person who may be in danger is silently recording ambient audio nearby.
Given a short transcript of what it overheard — someone else's speech,
not the phone owner's — judge whether it indicates the phone owner is
being threatened, restrained, silenced, or coerced by someone present.

Respond with ONLY a compact JSON object, no prose, in this exact shape:
{"level": "none|caution|danger", "reason": "one short sentence, in English"}

Guidance:
- "danger": clear signs of restraint, coercion, threats, silencing, or
  forced movement directed at the phone owner or someone with them —
  e.g. "make her quiet", "tie her up", "get in the car", "don't scream",
  "shut up", "don't move".
- "caution": tense, aggressive, or ambiguous language that could precede
  danger but is not explicit yet.
- "none": ordinary conversation — food, work, errands, small talk,
  directions — with nothing indicating threat or coercion. Most everyday
  conversation is "none"; do not over-flag it.

Judge the meaning of the whole transcript, not isolated words.`;

/// Everything Sarvam-related for the app lives here, keyed off the
/// admin-provisioned SARVAM_API_KEY — the app itself never holds or sends
/// a Sarvam key. Every method is honest about failure: a transcription or
/// classification that didn't happen returns `analyzed: false` with a
/// plain-language reason, never a guessed or fabricated result.
class SarvamService {
  async analyzeVoice(audio: Buffer, filename: string, mimeType: string): Promise<AnalysisResult> {
    let transcript = '';
    let detectedLanguage: string | null = null;
    try {
      const result = await this.transcribe(audio, filename, mimeType);
      transcript = result.transcript;
      detectedLanguage = result.language;
    } catch (error) {
      logger.warn({ err: error }, 'sarvam: voice transcription failed');
      return { analyzed: false, transcript: '', detectedLanguage: null, threatType: null, summary: 'Voice analysis failed for this recording.' };
    }

    if (!transcript.trim()) {
      return { analyzed: false, transcript: '', detectedLanguage, threatType: null, summary: 'No clear speech was captured in this recording.' };
    }

    return this.classifyReport(transcript, detectedLanguage);
  }

  async analyzeText(message: string): Promise<AnalysisResult> {
    const trimmed = message.trim();
    if (!trimmed) {
      return { analyzed: false, transcript: '', detectedLanguage: null, threatType: null, summary: 'No message was provided.' };
    }
    return this.classifyReport(trimmed, null);
  }

  private async classifyReport(transcript: string, detectedLanguage: string | null): Promise<AnalysisResult> {
    try {
      const { threatType, summary } = await this.chatCompletion(REPORT_SYSTEM_PROMPT, transcript);
      const parsedType = THREAT_TYPES.includes(threatType as ThreatType) ? (threatType as ThreatType) : null;
      if (!parsedType) {
        throw new Error(`Unrecognized threat_type: ${threatType}`);
      }
      return { analyzed: true, transcript, detectedLanguage, threatType: parsedType, summary };
    } catch (error) {
      logger.warn({ err: error }, 'sarvam: report classification failed');
      return {
        analyzed: false,
        transcript,
        detectedLanguage,
        threatType: null,
        summary: `Reported: "${transcript}" — AI analysis failed.`,
      };
    }
  }

  async assessAmbient(audio: Buffer, filename: string, mimeType: string): Promise<AmbientResult> {
    let transcript = '';
    try {
      const result = await this.transcribe(audio, filename, mimeType);
      transcript = result.transcript;
    } catch (error) {
      logger.warn({ err: error }, 'sarvam: ambient transcription failed');
      return { analyzed: false, transcript: '', level: null, reason: 'Ambient audio analysis failed for this cycle.' };
    }

    if (!transcript.trim()) {
      return { analyzed: false, transcript: '', level: null, reason: 'No clear audio was captured this cycle.' };
    }

    try {
      const response = await this.chatCompletionRaw(AMBIENT_SYSTEM_PROMPT, transcript);
      const level = THREAT_LEVELS.includes(response.level as ThreatLevel) ? (response.level as ThreatLevel) : null;
      if (!level) {
        throw new Error(`Unrecognized level: ${response.level}`);
      }
      return { analyzed: true, transcript, level, reason: response.reason ?? 'Ambient audio assessed.' };
    } catch (error) {
      logger.warn({ err: error }, 'sarvam: ambient classification failed');
      return { analyzed: false, transcript, level: null, reason: 'Ambient audio analysis failed for this cycle.' };
    }
  }

  private async transcribe(audio: Buffer, filename: string, mimeType: string): Promise<{ transcript: string; language: string | null }> {
    const form = new FormData();
    form.set('language_code', 'unknown');
    form.set('model', 'saaras:v3');
    form.set('file', new Blob([audio], { type: mimeType }), filename);

    const response = await fetch(STT_URL, {
      method: 'POST',
      headers: { 'api-subscription-key': env.SARVAM_API_KEY },
      body: form,
    });

    if (!response.ok) {
      throw new Error(`Sarvam STT failed: ${response.status} ${await response.text()}`);
    }
    const body = (await response.json()) as { transcript?: string; language_code?: string };
    return { transcript: body.transcript ?? '', language: body.language_code ?? null };
  }

  private async chatCompletion(systemPrompt: string, userText: string): Promise<{ threatType: string; summary: string }> {
    const parsed = await this.chatCompletionRaw(systemPrompt, userText);
    return { threatType: parsed.threat_type ?? 'unknown', summary: parsed.summary ?? userText };
  }

  private async chatCompletionRaw(systemPrompt: string, userText: string): Promise<Record<string, string>> {
    const response = await fetch(CHAT_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.SARVAM_API_KEY}`,
        'api-subscription-key': env.SARVAM_API_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'sarvam-105b-conversations',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userText },
        ],
        temperature: 0.1,
        max_tokens: 150,
      }),
    });

    if (!response.ok) {
      throw new Error(`Sarvam chat failed: ${response.status} ${await response.text()}`);
    }

    const body = (await response.json()) as { choices: Array<{ message: { content: string } }> };
    const content = body.choices[0]?.message.content ?? '{}';
    const start = content.indexOf('{');
    const end = content.lastIndexOf('}');
    if (start === -1 || end === -1) {
      throw new Error(`Sarvam chat returned no JSON: ${content}`);
    }
    return JSON.parse(content.slice(start, end + 1)) as Record<string, string>;
  }
}

export const sarvamService = new SarvamService();
