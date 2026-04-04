/**
 * Chrome LanguageModel (Prompt API) session wrapper.
 * No DOM dependencies — works in any context where LanguageModel is available.
 */

import { debugLog, debugPatch } from './debug-log.js';

const EXPECTED_INPUTS = [{ type: 'text', languages: ['en'] }];
const EXPECTED_OUTPUTS = [{ type: 'text', languages: ['en'] }];

/**
 * Check if the Prompt API is available.
 * @returns {'available' | 'downloadable' | 'downloading' | 'unavailable' | 'unsupported'}
 */
export async function checkAvailability() {
  if (!('LanguageModel' in self)) return 'unsupported';
  return LanguageModel.availability({
    expectedInputs: EXPECTED_INPUTS,
    expectedOutputs: EXPECTED_OUTPUTS,
  });
}

/**
 * Create a new LanguageModel session.
 * @param {string} systemPrompt
 * @param {{ onDownloadProgress?: Function, signal?: AbortSignal }} options
 * @returns {Promise<object>} session
 */
export async function createSession(systemPrompt, { onDownloadProgress, signal } = {}) {
  const session = await LanguageModel.create({
    initialPrompts: [{ role: 'system', content: systemPrompt }],
    expectedInputs: EXPECTED_INPUTS,
    expectedOutputs: EXPECTED_OUTPUTS,
    signal,
    ...(onDownloadProgress && {
      monitor(m) {
        m.addEventListener('downloadprogress', onDownloadProgress);
      },
    }),
  });
  debugLog('phase', { phase: 'session-created', systemPrompt });
  return session;
}

const PROMPT_TIMEOUT_MS = 30_000; // idle/stall window — resets on each token

/**
 * Prompt a session and parse the response as JSON using responseConstraint.
 * @param {object} session
 * @param {string} userMessage
 * @param {object} jsonSchema - JSON Schema for responseConstraint
 * @param {AbortSignal} [signal]
 * @returns {Promise<object>} parsed JSON
 */
export async function promptJSON(session, userMessage, jsonSchema, signal) {
  // Idle/stall timeout: the timer resets on every received token.
  // Only fires if the stream produces no new tokens for PROMPT_TIMEOUT_MS.
  // This prevents false timeouts when the model is slow but still progressing,
  // while still catching a genuinely hung stream.
  const stallController = new AbortController();
  let stallTimer = null;
  const resetStall = () => {
    clearTimeout(stallTimer);
    stallTimer = setTimeout(
      () => stallController.abort(new DOMException(`prompt stalled for ${PROMPT_TIMEOUT_MS}ms`, 'TimeoutError')),
      PROMPT_TIMEOUT_MS
    );
  };
  const combinedSignal = signal
    ? AbortSignal.any([signal, stallController.signal])
    : stallController.signal;

  const opts = {
    responseConstraint: jsonSchema,
    omitResponseConstraintInput: true,
    signal: combinedSignal,
  };
  console.groupCollapsed('[LazyBookmarks] AI prompt');
  console.log(userMessage);
  console.groupEnd();
  debugLog('prompt', { message: userMessage, schema: jsonSchema });
  // Initialise raw before the try so the rescue check in catch can see it.
  let raw = '';
  try {
    // promptStreaming() with responseConstraint returns incremental tokens,
    // not cumulative chunks. Accumulate into raw so JSON.parse sees the full
    // response. The constrained decoder prefixes output with whitespace —
    // trim the accumulated string before patching the debug view.
    const streamId = debugLog('stream', { text: '' });
    const stream = session.promptStreaming(userMessage, opts);
    resetStall();                         // arm stall timer before first token
    for await (const chunk of stream) {
      resetStall();                       // reset on every received token
      raw += chunk;
      debugPatch(streamId, raw.trim());
    }
  } catch (err) {
    // The iterator may hang indefinitely after the last token without ever
    // signalling done. If the stall timer fired but raw is non-empty, the
    // response is likely complete — fall through to JSON.parse which will
    // confirm. If raw is empty (model never started) or the error is not a
    // stall timeout, propagate normally.
    if (!(err.name === 'TimeoutError' && raw)) {
      debugLog('error', { message: err.name === 'TimeoutError' ? `prompt stalled for ${PROMPT_TIMEOUT_MS}ms` : err.message });
      throw err;
    }
    debugLog('phase', { phase: 'stream-stall-rescued', rawLength: raw.length });
  } finally {
    clearTimeout(stallTimer);
  }
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (err) {
    // responseConstraint should guarantee valid JSON — log the raw text so
    // debug.html shows exactly what the model returned.
    debugLog('error', { message: `JSON parse failed: ${err.message}`, raw });
    throw err;
  }
  console.groupCollapsed('[LazyBookmarks] AI response');
  console.log(parsed);
  console.groupEnd();
  debugLog('response', { parsed });
  return parsed;
}

// --- Compat shim for Prompt API rename (Chrome ships old names, spec has new) ---
// TODO: Remove shim once Chrome ships contextUsage/contextWindow/measureContextUsage
// Spec: https://github.com/webmachinelearning/prompt-api#context-window-management
const _usage = (s) => s.inputUsage ?? s.contextUsage;
const _window = (s) => s.inputQuota ?? s.contextWindow;
const _measure = (s, input) => (s.measureInputUsage ?? s.measureContextUsage).call(s, input);

/**
 * Get session quota information.
 * @param {object} session
 * @returns {{ usage: number, window: number, remaining: number }}
 */
export function getQuota(session) {
  const quota = {
    usage: _usage(session),
    window: _window(session),
    remaining: _window(session) - _usage(session),
  };
  debugLog('quota', quota);
  return quota;
}

/**
 * Measure how many tokens a prompt would consume.
 * @param {object} session
 * @param {string} input
 * @returns {Promise<number>}
 */
export function measureUsage(session, input) {
  return _measure(session, input);
}

/**
 * Clone a session, preserving its current context (system prompt + conversation history).
 * @param {object} session
 * @param {AbortSignal} [signal]
 * @returns {Promise<object>} cloned session
 */
export function cloneSession(session, signal) {
  return session.clone({ signal });
}

/**
 * Destroy a session to free resources.
 * @param {object} session
 */
export function destroySession(session) {
  if (session) session.destroy();
}
