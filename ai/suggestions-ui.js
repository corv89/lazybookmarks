/**
 * Inline suggestion annotations on tree bookmark items.
 * Shows target folder, confidence, reason, and accept/dismiss per item.
 * Floating action bar for bulk operations.
 */

/**
 * Initialize the suggestions UI.
 *
 * @param {HTMLElement} treeContainer - The tree container element
 * @param {object} callbacks
 * @param {Function} callbacks.expandPathTo - (nodeId) Expand tree to reveal a bookmark
 * @param {Function} callbacks.onApply - (accepted) Called when user clicks Apply
 * @param {Function} callbacks.onUndo - Called when user clicks Undo
 * @param {Function} callbacks.onCancel - Called when user cancels
 * @returns {{ addSuggestion, clearAll, getAccepted, getPending, showUndoButton, destroy }}
 */
export function initSuggestionsUI(treeContainer, callbacks) {
  const suggestions = new Map(); // bookmarkId -> { data, el, status: 'pending'|'accepted'|'dismissed' }
  const newFolderSuggestions = []; // newFolder suggestions
  let actionBar = null;

  function createActionBar() {
    if (actionBar) return;
    actionBar = document.createElement('div');
    actionBar.className = 'suggestion-action-bar';

    const countSpan = document.createElement('span');
    countSpan.className = 'suggestion-count';

    const actionsDiv = document.createElement('div');
    actionsDiv.className = 'suggestion-actions';

    const buttons = [
      { cls: 'btn-accept-high', text: 'Accept High', title: 'Accept high confidence suggestions' },
      { cls: 'btn-accept-all', text: 'Accept All', title: 'Accept all suggestions' },
      { cls: 'btn-dismiss-all', text: 'Dismiss All', title: 'Dismiss all suggestions' },
      { cls: 'btn-apply', text: 'Apply', title: 'Apply accepted moves', disabled: true },
      { cls: 'btn-cancel', text: 'Cancel', title: 'Cancel organization' },
      { cls: 'btn-undo', text: 'Undo', title: 'Undo last applied changes', hidden: true },
    ];

    for (const b of buttons) {
      const btn = document.createElement('button');
      btn.className = b.cls;
      btn.textContent = b.text;
      btn.title = b.title;
      if (b.disabled) btn.disabled = true;
      if (b.hidden) btn.hidden = true;
      actionsDiv.appendChild(btn);
    }

    actionBar.appendChild(countSpan);
    actionBar.appendChild(actionsDiv);
    document.body.appendChild(actionBar);

    actionBar.querySelector('.btn-accept-high').addEventListener('click', () => {
      for (const [, s] of suggestions) {
        if (s.status === 'pending' && s.data.confidence === 'high') {
          setSuggestionStatus(s, 'accepted');
        }
      }
      updateCounts();
    });

    actionBar.querySelector('.btn-accept-all').addEventListener('click', () => {
      for (const [, s] of suggestions) {
        if (s.status === 'pending') {
          setSuggestionStatus(s, 'accepted');
        }
      }
      updateCounts();
    });

    actionBar.querySelector('.btn-dismiss-all').addEventListener('click', () => {
      for (const [, s] of suggestions) {
        if (s.status === 'pending' || s.status === 'accepted') {
          setSuggestionStatus(s, 'dismissed');
        }
      }
      updateCounts();
    });

    actionBar.querySelector('.btn-apply').addEventListener('click', () => {
      const accepted = getAccepted();
      if (accepted.length > 0) {
        callbacks.onApply(accepted);
      }
    });

    actionBar.querySelector('.btn-cancel').addEventListener('click', () => {
      clearAll();
      callbacks.onCancel();
    });

    actionBar.querySelector('.btn-undo').addEventListener('click', () => {
      callbacks.onUndo();
    });
  }

  function setSuggestionStatus(s, status) {
    s.status = status;
    if (s.el) {
      s.el.classList.toggle('suggestion-accepted', status === 'accepted');
      s.el.classList.toggle('suggestion-dismissed', status === 'dismissed');
      const li = s.el.closest('li[data-bookmark-id]');
      if (li) {
        li.classList.toggle('has-suggestion', status !== 'dismissed');
      }
    }
  }

  function updateCounts() {
    if (!actionBar) return;
    const pending = [...suggestions.values()].filter(s => s.status === 'pending').length;
    const accepted = [...suggestions.values()].filter(s => s.status === 'accepted').length;
    const total = suggestions.size;

    let text = `${total} suggestion${total !== 1 ? 's' : ''}`;
    if (accepted > 0) text += ` (${accepted} accepted)`;
    if (pending > 0) text += ` (${pending} pending)`;
    if (newFolderSuggestions.length > 0) {
      const names = newFolderSuggestions.map(nf => nf.suggestedName).join(', ');
      text += ` + ${newFolderSuggestions.length} new folder${newFolderSuggestions.length !== 1 ? 's' : ''}: ${names}`;
    }
    actionBar.querySelector('.suggestion-count').textContent = text;

    const applyBtn = actionBar.querySelector('.btn-apply');
    applyBtn.disabled = accepted === 0;
    applyBtn.textContent = accepted > 0 ? `Apply (${accepted})` : 'Apply';
  }

  function buildAnnotation(suggestion) {
    const el = document.createElement('div');
    el.className = `suggestion-annotation confidence-${suggestion.confidence}`;

    const arrow = document.createElement('span');
    arrow.className = 'suggestion-arrow';
    arrow.setAttribute('aria-hidden', 'true');
    arrow.textContent = '\u2192'; // →

    const target = document.createElement('span');
    target.className = 'suggestion-target';
    target.textContent = suggestion.targetFolderPath;

    const reason = document.createElement('span');
    reason.className = 'suggestion-reason';
    reason.textContent = suggestion.reason;

    const acceptBtn = document.createElement('button');
    acceptBtn.className = 'suggestion-accept';
    acceptBtn.title = 'Accept this suggestion';
    acceptBtn.setAttribute('aria-label', 'Accept suggestion');
    acceptBtn.textContent = '\u2714'; // ✔

    const dismissBtn = document.createElement('button');
    dismissBtn.className = 'suggestion-dismiss';
    dismissBtn.title = 'Dismiss this suggestion';
    dismissBtn.setAttribute('aria-label', 'Dismiss suggestion');
    dismissBtn.textContent = '\u2716'; // ✖

    el.append(arrow, target, reason, acceptBtn, dismissBtn);
    return el;
  }

  /**
   * Add a suggestion annotation to a bookmark in the tree.
   * @param {object} suggestion
   */
  function addSuggestion(suggestion) {
    if (suggestion.type === 'newFolder') {
      newFolderSuggestions.push(suggestion);
      updateCounts();
      return;
    }

    const { bookmarkId } = suggestion;
    if (suggestions.has(bookmarkId)) return; // Don't duplicate

    // Ensure the bookmark is visible in the tree
    callbacks.expandPathTo(bookmarkId);

    const li = treeContainer.querySelector(`li[data-bookmark-id="${bookmarkId}"]`);
    if (!li) return;

    const el = buildAnnotation(suggestion);
    const entry = { data: suggestion, el, status: 'pending' };

    el.querySelector('.suggestion-accept').addEventListener('click', (e) => {
      e.stopPropagation();
      setSuggestionStatus(entry, entry.status === 'accepted' ? 'pending' : 'accepted');
      updateCounts();
    });

    el.querySelector('.suggestion-dismiss').addEventListener('click', (e) => {
      e.stopPropagation();
      setSuggestionStatus(entry, 'dismissed');
      updateCounts();
    });

    li.classList.add('has-suggestion');
    li.appendChild(el);

    suggestions.set(bookmarkId, entry);

    createActionBar();
    updateCounts();
  }

  /**
   * Get all accepted suggestions (moves + relevant new folders).
   * New folders are only included if at least one of their bookmarks
   * has an accepted move suggestion.
   * @returns {Array}
   */
  function getAccepted() {
    const moves = [...suggestions.values()]
      .filter(s => s.status === 'accepted')
      .map(s => s.data);
    const acceptedIds = new Set(moves.map(m => m.bookmarkId));
    // Only include new folder suggestions that have at least one accepted bookmark
    const folders = newFolderSuggestions.filter(nf =>
      nf.bookmarkIds.some(id => acceptedIds.has(id))
    );
    return [...moves, ...folders];
  }

  /**
   * Get count of pending suggestions.
   * @returns {number}
   */
  function getPending() {
    return [...suggestions.values()].filter(s => s.status === 'pending').length;
  }

  /**
   * Clear all suggestions and remove annotations.
   */
  function clearAll() {
    for (const [, s] of suggestions) {
      if (s.el) s.el.remove();
      const li = treeContainer.querySelector(`li[data-bookmark-id="${s.data.bookmarkId}"]`);
      if (li) li.classList.remove('has-suggestion');
    }
    suggestions.clear();
    newFolderSuggestions.length = 0;
    if (actionBar) {
      actionBar.remove();
      actionBar = null;
    }
  }

  /**
   * Show the Undo button (after a successful apply).
   */
  function showUndoButton() {
    createActionBar();
    actionBar.querySelector('.btn-undo').hidden = false;
    actionBar.querySelector('.btn-accept-high').hidden = true;
    actionBar.querySelector('.btn-accept-all').hidden = true;
    actionBar.querySelector('.btn-dismiss-all').hidden = true;
    actionBar.querySelector('.btn-apply').hidden = true;
    actionBar.querySelector('.btn-cancel').hidden = true;
    actionBar.querySelector('.suggestion-count').textContent = 'Changes applied.';
  }

  /**
   * Clean up and remove action bar.
   */
  function destroy() {
    clearAll();
  }

  return { addSuggestion, clearAll, getAccepted, getPending, showUndoButton, destroy };
}
