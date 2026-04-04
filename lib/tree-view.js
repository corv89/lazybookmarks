/**
 * ARIA-compliant tree component with lazy rendering and keyboard navigation.
 * W3C APG Tree View pattern: https://www.w3.org/WAI/ARIA/apg/patterns/treeview/
 */
import { createFavicon } from './favicon.js';

/**
 * Initialize the tree component. Call once — returns a control API.
 *
 * @param {HTMLElement} container - The tree container element.
 * @param {{ folderTpl: HTMLTemplateElement, bookmarkTpl: HTMLTemplateElement }} templates
 * @param {{ onToggle: (collapsed: Set) => void }} callbacks
 * @returns {{ render, expandAll, collapseAll, focusFirst }}
 */
export function initTree(container, templates, callbacks) {
  let currentStats = new Map();
  let currentCollapsed = new Set();
  let currentNodeById = new Map();

  // Single click listener via event delegation
  container.addEventListener('click', (e) => {
    const header = e.target.closest('.folder-header');
    if (!header) return;

    const li = header.closest('li[role="treeitem"]');
    if (!li) return;

    // Empty folders have no aria-expanded
    if (!li.hasAttribute('aria-expanded')) return;

    toggleFolder(li);
  });

  // Keyboard navigation on the container
  container.addEventListener('keydown', (e) => {
    const focusable = getFocusableItems(container);
    if (focusable.length === 0) return;

    const active = document.activeElement;
    const idx = focusable.indexOf(active);

    switch (e.key) {
      case 'ArrowDown': {
        e.preventDefault();
        const next = idx < focusable.length - 1 ? idx + 1 : 0;
        setFocus(focusable, next);
        break;
      }
      case 'ArrowUp': {
        e.preventDefault();
        const prev = idx > 0 ? idx - 1 : focusable.length - 1;
        setFocus(focusable, prev);
        break;
      }
      case 'ArrowRight': {
        e.preventDefault();
        const li = active?.closest('li[role="treeitem"]');
        if (li && li.getAttribute('aria-expanded') === 'false') {
          toggleFolder(li);
          // After expanding, focus stays on the folder header
        } else if (li && li.getAttribute('aria-expanded') === 'true') {
          // Move to first child
          const group = li.querySelector(':scope > ul[role="group"]');
          if (group) {
            const firstChild = group.querySelector('.folder-header, a[role="treeitem"]');
            if (firstChild) {
              const newFocusables = getFocusableItems(container);
              const childIdx = newFocusables.indexOf(firstChild);
              if (childIdx >= 0) setFocus(newFocusables, childIdx);
            }
          }
        }
        break;
      }
      case 'ArrowLeft': {
        e.preventDefault();
        const li = active?.closest('li[role="treeitem"]');
        if (li && li.getAttribute('aria-expanded') === 'true') {
          toggleFolder(li);
        } else if (li) {
          // Move to parent folder
          const parentGroup = li.closest('ul[role="group"]');
          if (parentGroup) {
            const parentLi = parentGroup.closest('li[role="treeitem"]');
            if (parentLi) {
              const parentHeader = parentLi.querySelector(':scope > .folder-header');
              if (parentHeader) {
                const newFocusables = getFocusableItems(container);
                const parentIdx = newFocusables.indexOf(parentHeader);
                if (parentIdx >= 0) setFocus(newFocusables, parentIdx);
              }
            }
          }
        }
        break;
      }
      case 'Home': {
        e.preventDefault();
        setFocus(focusable, 0);
        break;
      }
      case 'End': {
        e.preventDefault();
        setFocus(focusable, focusable.length - 1);
        break;
      }
      case 'Enter':
      case ' ': {
        e.preventDefault();
        const li = active?.closest('li[role="treeitem"]');
        if (li && li.hasAttribute('aria-expanded')) {
          toggleFolder(li);
        } else if (active?.tagName === 'A') {
          active.click();
        }
        break;
      }
      default: {
        // Type-ahead: single printable character
        if (e.key.length === 1 && !e.ctrlKey && !e.altKey && !e.metaKey) {
          const char = e.key.toLowerCase();
          const start = idx + 1;
          for (let i = 0; i < focusable.length; i++) {
            const candidate = focusable[(start + i) % focusable.length];
            const text = getItemText(candidate).toLowerCase();
            if (text.startsWith(char)) {
              setFocus(focusable, (start + i) % focusable.length);
              break;
            }
          }
        }
      }
    }
  });

  function toggleFolder(li) {
    const id = li.dataset.folderId;
    const wasExpanded = li.getAttribute('aria-expanded') === 'true';

    if (wasExpanded) {
      li.setAttribute('aria-expanded', 'false');
      const group = li.querySelector(':scope > ul[role="group"]');
      if (group) group.hidden = true;
      currentCollapsed.add(id);
    } else {
      li.setAttribute('aria-expanded', 'true');
      // Lazy render: build children on first expand
      let group = li.querySelector(':scope > ul[role="group"]');
      if (!group) {
        const node = findNode(id);
        if (node && node.children) {
          const level = parseInt(li.getAttribute('aria-level'), 10);
          group = buildGroup(node.children, level + 1);
          li.appendChild(group);
        }
      }
      if (group) group.hidden = false;
      currentCollapsed.delete(id);
    }

    callbacks.onToggle(currentCollapsed);
  }

  function findNode(id) {
    return currentNodeById.get(id) || null;
  }

  function buildGroup(nodes, level) {
    const ul = document.createElement('ul');
    ul.setAttribute('role', 'group');
    ul.className = 'tree-children';

    for (const node of nodes) {
      if (node.isFolder) {
        ul.appendChild(buildFolder(node, level));
      } else {
        ul.appendChild(buildBookmark(node, level));
      }
    }
    return ul;
  }

  function buildFolder(node, level) {
    const frag = templates.folderTpl.content.cloneNode(true);
    const li = frag.querySelector('li');
    li.dataset.folderId = node.id;
    li.setAttribute('aria-level', level);

    const header = li.querySelector('.folder-header');
    const titleEl = li.querySelector('.folder-title');
    titleEl.textContent = node.title || '(untitled)';

    const isEmpty = node.isEmpty;

    if (isEmpty) {
      // Empty folders: no expand/collapse, no chevron
      li.removeAttribute('aria-expanded');
      li.querySelector('.chevron').remove();
      li.querySelector('.count-badge').remove();
    } else {
      const isCollapsed = currentCollapsed.has(node.id);
      li.setAttribute('aria-expanded', isCollapsed ? 'false' : 'true');

      const s = currentStats.get(node.id);
      if (s && s.bookmarkCount > 0) {
        const badge = li.querySelector('.count-badge');
        badge.textContent = s.bookmarkCount;
        badge.setAttribute('aria-label', `${s.bookmarkCount} bookmarks, ${s.folderCount} folders`);
      } else {
        li.querySelector('.count-badge').remove();
      }

      // Lazy rendering: only build children if expanded
      if (!isCollapsed) {
        const group = buildGroup(node.children, level + 1);
        li.appendChild(group);
      }
      // If collapsed, children will be built on first expand
    }

    return li;
  }

  function buildBookmark(node, level) {
    const frag = templates.bookmarkTpl.content.cloneNode(true);
    const li = frag.querySelector('li');
    li.dataset.bookmarkId = node.id;
    const a = li.querySelector('a');
    a.href = node.url || '#';
    a.title = node.url || '';
    a.setAttribute('aria-level', level);

    const favicon = createFavicon(node.url);
    a.insertBefore(favicon, a.firstChild);

    const titleEl = li.querySelector('.bookmark-title');
    titleEl.textContent = node.title || node.url || '(untitled)';

    return li;
  }

  /**
   * Render the full tree from data.
   */
  function render(nodes, stats, collapsed, nodeById) {
    currentNodeById = nodeById;
    currentStats = stats;
    currentCollapsed = collapsed;

    const ul = document.createElement('ul');
    ul.setAttribute('role', 'tree');
    ul.setAttribute('aria-label', 'Bookmarks');
    ul.className = 'tree-list';

    for (const node of nodes) {
      if (node.isFolder) {
        ul.appendChild(buildFolder(node, 1));
      } else {
        ul.appendChild(buildBookmark(node, 1));
      }
    }

    container.replaceChildren(ul);

    // Set first item as tabbable (roving tabindex)
    const first = container.querySelector('.folder-header, a[role="treeitem"]');
    if (first) first.tabIndex = 0;
  }

  function expandAll() {
    // Re-query after each pass — expanding a folder lazily renders children
    // that may themselves be collapsed and need expanding.
    let remaining;
    while ((remaining = container.querySelectorAll('li[aria-expanded="false"]')).length > 0) {
      for (const li of remaining) {
        const id = li.dataset.folderId;
        li.setAttribute('aria-expanded', 'true');
        currentCollapsed.delete(id);

        let group = li.querySelector(':scope > ul[role="group"]');
        if (!group) {
          const node = findNode(id);
          if (node && node.children) {
            const level = parseInt(li.getAttribute('aria-level'), 10);
            group = buildGroup(node.children, level + 1);
            li.appendChild(group);
          }
        }
        if (group) group.hidden = false;
      }
    }
    callbacks.onToggle(currentCollapsed);
  }

  function collapseAll() {
    for (const li of container.querySelectorAll('li[aria-expanded]')) {
      li.setAttribute('aria-expanded', 'false');
      currentCollapsed.add(li.dataset.folderId);
      const group = li.querySelector(':scope > ul[role="group"]');
      if (group) group.hidden = true;
    }
    callbacks.onToggle(currentCollapsed);
  }

  function focusFirst() {
    const first = container.querySelector('.folder-header, a[role="treeitem"]');
    if (first) {
      first.tabIndex = 0;
      first.focus();
    }
  }

  /**
   * Expand all ancestor folders to reveal the node with the given ID.
   * Walks the parent chain via nodeById, expands top-down (root toward target).
   * Forces lazy rendering at each level since ancestors may not exist in DOM yet.
   */
  function expandPathTo(nodeId) {
    const node = currentNodeById.get(nodeId);
    if (!node) return;

    // Build ancestor chain (excluding the node itself)
    const ancestors = [];
    let current = node;
    while (current.parentId) {
      const parent = currentNodeById.get(current.parentId);
      if (!parent) break;
      if (parent.isFolder) ancestors.push(parent.id);
      current = parent;
    }

    // Expand top-down so lazy rendering builds children at each level
    ancestors.reverse();
    for (const ancestorId of ancestors) {
      const li = container.querySelector(`li[data-folder-id="${ancestorId}"]`);
      if (!li) continue;
      if (li.getAttribute('aria-expanded') === 'false') {
        toggleFolder(li);
      }
    }
  }

  return { render, expandAll, collapseAll, focusFirst, expandPathTo };
}

/** Get all visible focusable items in the tree (folder headers + bookmark links). */
function getFocusableItems(container) {
  const items = [];
  const walk = (el) => {
    for (const child of el.children) {
      if (child.hidden) continue;

      if (child.matches('.folder-header')) {
        items.push(child);
      } else if (child.matches('a[role="treeitem"]')) {
        items.push(child);
      }

      walk(child);
    }
  };
  walk(container);
  return items;
}

/** Set focus with roving tabindex. */
function setFocus(focusables, index) {
  for (const el of focusables) el.tabIndex = -1;
  focusables[index].tabIndex = 0;
  focusables[index].focus();
}

/** Get the visible text of a focusable tree item. */
function getItemText(el) {
  if (el.matches('.folder-header')) {
    return el.querySelector('.folder-title')?.textContent || '';
  }
  return el.querySelector('.bookmark-title')?.textContent || el.textContent || '';
}
