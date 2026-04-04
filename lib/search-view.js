/**
 * Search UI component — debounced input, result rendering, Escape to clear.
 * Orama integration stays in viewer.js; this module receives a search callback.
 */
import { createFavicon } from './favicon.js';

/**
 * Initialize the search component. Call once.
 *
 * @param {HTMLInputElement} input - The search input element.
 * @param {HTMLElement} resultsContainer - Container for search result cards.
 * @param {{ onSearch: (query: string) => Array, onClear: () => void }} callbacks
 */
export function initSearch(input, resultsContainer, callbacks) {
  let timer = null;

  input.addEventListener('input', () => {
    clearTimeout(timer);
    timer = setTimeout(() => {
      const query = input.value.trim();
      if (!query) {
        callbacks.onClear();
        return;
      }
      const results = callbacks.onSearch(query);
      renderResults(resultsContainer, results);
    }, 200);
  });

  input.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      input.value = '';
      clearTimeout(timer);
      callbacks.onClear();
    }
  });
}

function renderResults(container, results) {
  container.replaceChildren();

  if (results.length === 0) {
    const empty = document.createElement('p');
    empty.className = 'search-result-path';
    empty.textContent = 'No results found.';
    empty.style.padding = '24px 0';
    container.appendChild(empty);
    return;
  }

  for (const r of results) {
    const card = document.createElement('div');
    card.className = 'search-result';

    const titleRow = document.createElement('div');
    titleRow.className = 'search-result-title';

    if (r.url) titleRow.appendChild(createFavicon(r.url));

    const link = document.createElement('a');
    link.href = r.url;
    link.target = '_blank';
    link.rel = 'noopener';
    link.textContent = r.title || r.url;
    titleRow.appendChild(link);
    card.appendChild(titleRow);

    if (r.url) {
      const urlLine = document.createElement('div');
      urlLine.className = 'search-result-url';
      urlLine.textContent = r.url;
      card.appendChild(urlLine);
    }

    if (r.path) {
      const pathLine = document.createElement('div');
      pathLine.className = 'search-result-path';
      pathLine.textContent = r.path;
      card.appendChild(pathLine);
    }

    container.appendChild(card);
  }
}
