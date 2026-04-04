import { CHANNEL_NAME, STORAGE_KEY } from '../ai/debug-constants.js';

const logContainer = document.getElementById('log');
const clearBtn = document.getElementById('clear-btn');
const statusEl = document.getElementById('status');

let userScrolledUp = false;

window.addEventListener('scroll', () => {
  const atBottom = (window.innerHeight + window.scrollY) >= (document.body.scrollHeight - 40);
  userScrolledUp = !atBottom;
}, { passive: true });

function updateStatus() {
  statusEl.textContent = `Live — ${logContainer.childElementCount} entries`;
}

function formatTime(ts) {
  const d = new Date(ts);
  const h = String(d.getHours()).padStart(2, '0');
  const m = String(d.getMinutes()).padStart(2, '0');
  const s = String(d.getSeconds()).padStart(2, '0');
  const ms = String(d.getMilliseconds()).padStart(3, '0');
  return `${h}:${m}:${s}.${ms}`;
}

function byteSize(data) {
  const bytes = new TextEncoder().encode(JSON.stringify(data)).length;
  if (bytes < 1024) return `${bytes} B`;
  return `${(bytes / 1024).toFixed(1)} KB`;
}

function getPreviewText(type, data) {
  switch (type) {
    case 'prompt':   return (data.message || '').slice(0, 80);
    case 'stream':   return (data.text || '').slice(0, 80) || 'waiting…';
    case 'response': return JSON.stringify(data.parsed).slice(0, 80);
    case 'error':    return data.message || '';
    case 'phase':    return data.phase || '';
    case 'quota':    return `${data.usage}/${data.window}`;
    default:         return JSON.stringify(data).slice(0, 80);
  }
}

function renderContent(type, data) {
  switch (type) {
    case 'prompt': {
      const pre = document.createElement('pre');
      pre.textContent = data.message || '';
      const wrapper = document.createElement('div');
      wrapper.appendChild(pre);
      if (data.schema) {
        const schemaLabel = document.createElement('p');
        schemaLabel.className = 'schema-label';
        schemaLabel.textContent = 'Schema:';
        const schemaPre = document.createElement('pre');
        schemaPre.textContent = JSON.stringify(data.schema, null, 2);
        wrapper.appendChild(schemaLabel);
        wrapper.appendChild(schemaPre);
      }
      return wrapper;
    }
    case 'stream': {
      const pre = document.createElement('pre');
      pre.className = 'stream-text';
      pre.textContent = data.text || '';
      return pre;
    }
    case 'response': {
      const pre = document.createElement('pre');
      pre.textContent = JSON.stringify(data.parsed, null, 2);
      return pre;
    }
    case 'error': {
      const wrapper = document.createElement('div');
      const span = document.createElement('span');
      span.className = 'error-text';
      span.textContent = data.message || JSON.stringify(data);
      wrapper.appendChild(span);
      if (data.raw != null) {
        const label = document.createElement('p');
        label.className = 'schema-label';
        label.textContent = 'Raw model output:';
        const pre = document.createElement('pre');
        pre.textContent = data.raw;
        wrapper.appendChild(label);
        wrapper.appendChild(pre);
      }
      if (data.batch) {
        const label = document.createElement('p');
        label.className = 'schema-label';
        label.textContent = `Bookmark IDs: ${data.batch.join(', ')}`;
        wrapper.appendChild(label);
      }
      return wrapper;
    }
    case 'phase': {
      const span = document.createElement('span');
      span.className = 'phase-text';
      span.textContent = data.phase || '';
      if (data.systemPrompt) {
        const wrapper = document.createElement('div');
        wrapper.appendChild(span);
        const pre = document.createElement('pre');
        pre.textContent = data.systemPrompt;
        wrapper.appendChild(pre);
        return wrapper;
      }
      return span;
    }
    case 'quota': {
      const span = document.createElement('span');
      span.className = 'quota-text';
      span.textContent = `Usage: ${data.usage} / ${data.window}  |  Remaining: ${data.remaining}`;
      return span;
    }
    default: {
      const pre = document.createElement('pre');
      pre.textContent = JSON.stringify(data, null, 2);
      return pre;
    }
  }
}

function buildEntryElement(entry) {
  const details = document.createElement('details');
  details.className = 'entry';
  details.dataset.id = entry.id;
  if (entry.type === 'stream') details.open = true;

  const summary = document.createElement('summary');
  summary.className = 'entry-summary';

  const time = document.createElement('span');
  time.className = 'entry-time';
  time.textContent = formatTime(entry.timestamp);

  const badge = document.createElement('span');
  badge.className = `entry-badge badge-${entry.type}`;
  badge.textContent = entry.type;

  const size = document.createElement('span');
  size.className = 'entry-size';
  size.textContent = byteSize(entry.data);

  const preview = document.createElement('span');
  preview.className = 'entry-preview';
  preview.textContent = getPreviewText(entry.type, entry.data);

  summary.append(time, badge, size, preview);
  details.appendChild(summary);

  const content = document.createElement('div');
  content.className = 'entry-content';
  content.appendChild(renderContent(entry.type, entry.data));
  details.appendChild(content);

  return details;
}

function addLiveEntry(entry) {
  logContainer.appendChild(buildEntryElement(entry));

  if (!userScrolledUp) {
    window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
  }

  updateStatus();
}

function clearLog() {
  chrome.storage.session.remove(STORAGE_KEY);
  logContainer.replaceChildren();
  updateStatus();
}

// Load history from storage, then go live
chrome.storage.session.get(STORAGE_KEY).then(result => {
  const log = result[STORAGE_KEY] || [];
  if (log.length) {
    const fragment = document.createDocumentFragment();
    for (const entry of log) {
      fragment.appendChild(buildEntryElement(entry));
    }
    logContainer.appendChild(fragment);
  }
  updateStatus();
  statusEl.classList.add('status-live');

  // Scroll to bottom after history load
  window.scrollTo({ top: document.body.scrollHeight });
});

// Listen for live entries and patch messages
const channel = new BroadcastChannel(CHANNEL_NAME);
channel.onmessage = (e) => {
  const msg = e.data;
  if (msg.__patch__) {
    const el = logContainer.querySelector(`[data-id="${msg.id}"]`);
    if (!el) return;
    const pre = el.querySelector('.stream-text');
    if (pre) pre.textContent = msg.text;
    const preview = el.querySelector('.entry-preview');
    if (preview) preview.textContent = msg.text.slice(0, 80);
    const size = el.querySelector('.entry-size');
    if (size) size.textContent = byteSize({ text: msg.text });
    return;
  }
  addLiveEntry(msg);
};

clearBtn.addEventListener('click', clearLog);
