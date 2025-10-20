/**
 * Vim-style navigation for the website
 * Supports: j/k (scroll), h/l (horizontal scroll), gg/G (top/bottom), / (search)
 */

(function() {
  'use strict';

  // State
  let searchMode = false;
  let searchQuery = '';
  let searchMatches = [];
  let currentMatchIndex = -1;
  let lastKeyWasG = false;
  let gTimeout = null;

  // Search overlay elements
  let searchOverlay = null;
  let searchInput = null;

  // Initialize search overlay
  function initSearchOverlay() {
    searchOverlay = document.createElement('div');
    searchOverlay.id = 'vim-search-overlay';

    // Create slash span and input separately for better control
    const slashSpan = document.createElement('span');
    slashSpan.textContent = '/';
    slashSpan.style.cssText = `
      display: inline-block;
      margin-right: 4px;
    `;

    searchInput = document.createElement('input');
    searchInput.type = 'text';
    searchInput.id = 'vim-search-input';
    searchInput.autocomplete = 'off';
    searchInput.spellcheck = false;

    searchOverlay.appendChild(slashSpan);
    searchOverlay.appendChild(searchInput);

    // Apply inline styles for vim-like appearance
    searchOverlay.style.cssText = `
      position: fixed;
      bottom: 20px;
      left: 20px;
      min-width: 200px;
      max-width: 400px;
      background-color: #292a2d;
      border: 1px solid #555;
      border-radius: 4px;
      padding: 6px 10px;
      font-family: 'Fira Mono', 'Courier New', monospace;
      color: #f8f8ff;
      z-index: 9999;
      display: none;
      font-size: 14px;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
      line-height: 1.4;
    `;

    document.body.appendChild(searchOverlay);

    // Apply inline styles to input
    searchInput.style.cssText = `
      background: transparent;
      border: none;
      color: #f8f8ff;
      font-family: 'Fira Mono', 'Courier New', monospace;
      font-size: 14px;
      outline: none;
      width: 180px;
      padding: 0;
      margin: 0;
      vertical-align: baseline;
    `;

    // Handle search input
    searchInput.addEventListener('input', function(e) {
      searchQuery = e.target.value;
      performSearch(searchQuery);
    });

    // Handle Enter, Escape, and navigation in search input
    searchInput.addEventListener('keydown', function(e) {
      if (e.key === 'Enter') {
        e.preventDefault();
        nextMatch();
      } else if (e.key === 'Escape') {
        e.preventDefault();
        exitSearchMode();
      } else if (e.key === 'n' && e.ctrlKey) {
        // Ctrl+n for next match while typing
        e.preventDefault();
        nextMatch();
      } else if (e.key === 'p' && e.ctrlKey) {
        // Ctrl+p for previous match while typing
        e.preventDefault();
        prevMatch();
      }
      // Let other keys propagate normally for typing
    });
  }

  // Check if user is typing in an input field
  function isTypingInInput() {
    const activeElement = document.activeElement;
    const tagName = activeElement.tagName.toLowerCase();
    return tagName === 'input' || tagName === 'textarea' || activeElement.isContentEditable;
  }

  // Scroll functions
  function scrollDown() {
    window.scrollBy({ top: 60, behavior: 'smooth' });
  }

  function scrollUp() {
    window.scrollBy({ top: -60, behavior: 'smooth' });
  }

  function scrollLeft() {
    window.scrollBy({ left: -60, behavior: 'smooth' });
  }

  function scrollRight() {
    window.scrollBy({ left: 60, behavior: 'smooth' });
  }

  function scrollToTop() {
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function scrollToBottom() {
    window.scrollTo({ top: document.body.scrollHeight, behavior: 'smooth' });
  }

  // Search functions
  function enterSearchMode() {
    searchMode = true;
    searchOverlay.style.display = 'block';
    searchInput.value = '';
    searchInput.focus();
    clearSearchHighlights();
  }

  function exitSearchMode() {
    searchMode = false;
    searchOverlay.style.display = 'none';
    searchInput.blur();
    clearSearchHighlights();
    searchQuery = '';
    searchMatches = [];
    currentMatchIndex = -1;
  }

  function clearSearchHighlights() {
    const highlights = document.querySelectorAll('.vim-search-match, .vim-search-current');
    highlights.forEach(el => {
      const parent = el.parentNode;
      parent.replaceChild(document.createTextNode(el.textContent), el);
      parent.normalize();
    });
  }

  function performSearch(query) {
    clearSearchHighlights();

    if (!query || query.length < 1) {
      searchMatches = [];
      currentMatchIndex = -1;
      return;
    }

    searchMatches = [];
    const walker = document.createTreeWalker(
      document.body,
      NodeFilter.SHOW_TEXT,
      {
        acceptNode: function(node) {
          // Skip script, style, and search overlay
          const parent = node.parentElement;
          if (!parent) return NodeFilter.FILTER_REJECT;
          const tagName = parent.tagName.toLowerCase();
          if (tagName === 'script' || tagName === 'style' || parent.closest('#vim-search-overlay')) {
            return NodeFilter.FILTER_REJECT;
          }
          return NodeFilter.FILTER_ACCEPT;
        }
      }
    );

    const nodesToHighlight = [];
    let node;
    while (node = walker.nextNode()) {
      const text = node.textContent;
      const regex = new RegExp(query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gi');
      if (regex.test(text)) {
        nodesToHighlight.push(node);
      }
    }

    // Highlight matches
    nodesToHighlight.forEach(node => {
      const text = node.textContent;
      const regex = new RegExp(`(${query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi');
      const parent = node.parentNode;
      const fragment = document.createDocumentFragment();

      let lastIndex = 0;
      let match;
      const tempRegex = new RegExp(query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'gi');

      while ((match = tempRegex.exec(text)) !== null) {
        // Add text before match
        if (match.index > lastIndex) {
          fragment.appendChild(document.createTextNode(text.substring(lastIndex, match.index)));
        }

        // Add highlighted match
        const span = document.createElement('span');
        span.className = 'vim-search-match';
        span.style.cssText = 'background-color: #ffff00; color: #000000; padding: 1px 2px;';
        span.textContent = match[0];
        fragment.appendChild(span);
        searchMatches.push(span);

        lastIndex = match.index + match[0].length;
      }

      // Add remaining text
      if (lastIndex < text.length) {
        fragment.appendChild(document.createTextNode(text.substring(lastIndex)));
      }

      parent.replaceChild(fragment, node);
    });

    // Highlight first match
    if (searchMatches.length > 0) {
      currentMatchIndex = 0;
      highlightCurrentMatch();
    }
  }

  function highlightCurrentMatch() {
    searchMatches.forEach((el, idx) => {
      if (idx === currentMatchIndex) {
        el.style.cssText = 'background-color: #ff9900; color: #000000; padding: 1px 2px;';
        el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      } else {
        el.style.cssText = 'background-color: #ffff00; color: #000000; padding: 1px 2px;';
      }
    });
  }

  function nextMatch() {
    if (searchMatches.length === 0) return;
    currentMatchIndex = (currentMatchIndex + 1) % searchMatches.length;
    highlightCurrentMatch();
  }

  function prevMatch() {
    if (searchMatches.length === 0) return;
    currentMatchIndex = (currentMatchIndex - 1 + searchMatches.length) % searchMatches.length;
    highlightCurrentMatch();
  }

  // Main keydown handler
  function handleKeyDown(e) {
    // Don't interfere with typing in input fields (except when in search mode)
    if (!searchMode && isTypingInInput()) {
      return;
    }

    // In search mode, most keys are handled by the input field
    // Only handle navigation keys that should work while in search mode
    if (searchMode && isTypingInInput()) {
      // Let the input handle typing, navigation handled by input listener
      return;
    }

    // Normal mode vim navigation
    switch(e.key) {
      case 'j':
        e.preventDefault();
        scrollDown();
        break;

      case 'k':
        e.preventDefault();
        scrollUp();
        break;

      case 'h':
        e.preventDefault();
        scrollLeft();
        break;

      case 'l':
        e.preventDefault();
        scrollRight();
        break;

      case 'g':
        e.preventDefault();
        if (lastKeyWasG) {
          scrollToTop();
          lastKeyWasG = false;
          if (gTimeout) clearTimeout(gTimeout);
        } else {
          lastKeyWasG = true;
          gTimeout = setTimeout(() => {
            lastKeyWasG = false;
          }, 500);
        }
        break;

      case 'G':
        e.preventDefault();
        scrollToBottom();
        lastKeyWasG = false;
        if (gTimeout) clearTimeout(gTimeout);
        break;

      case '/':
        e.preventDefault();
        enterSearchMode();
        break;

      case 'n':
        if (searchMatches.length > 0) {
          e.preventDefault();
          nextMatch();
        }
        break;

      case 'N':
        if (searchMatches.length > 0) {
          e.preventDefault();
          prevMatch();
        }
        break;

      case 'Escape':
        if (searchMode) {
          e.preventDefault();
          exitSearchMode();
        }
        break;
    }
  }

  // Initialize on DOM ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
      initSearchOverlay();
      document.addEventListener('keydown', handleKeyDown);
    });
  } else {
    initSearchOverlay();
    document.addEventListener('keydown', handleKeyDown);
  }

})();
