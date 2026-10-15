(function () {
  'use strict';

  var storageKey = 'vitepress-theme-appearance';
  var mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  var root = document.documentElement;
  var validModes = ['auto', 'dark', 'light'];

  function normalizeMode(mode) {
    return validModes.indexOf(mode) >= 0 ? mode : 'auto';
  }

  function readMode() {
    try {
      return normalizeMode(localStorage.getItem(storageKey) || 'auto');
    } catch (error) {
      return 'auto';
    }
  }

  function writeMode(mode) {
    var normalizedMode = normalizeMode(mode);
    try {
      if (normalizedMode === 'auto') {
        localStorage.removeItem(storageKey);
      } else {
        localStorage.setItem(storageKey, normalizedMode);
      }
    } catch (error) {
      // Ignore storage errors.
    }
  }

  function getAppearanceLabel(mode, isDark) {
    if (mode === 'dark') {
      return 'Appearance: Dark (forced). Click to force light.';
    }

    if (mode === 'light') {
      return 'Appearance: Light (forced). Click to follow system.';
    }

    return isDark
      ? 'Appearance: Auto (system dark). Click to force dark.'
      : 'Appearance: Auto (system light). Click to force dark.';
  }

  function applyMode(mode) {
    var normalizedMode = normalizeMode(mode);
    var dark = normalizedMode === 'dark' || (normalizedMode === 'auto' && mediaQuery.matches);
    root.classList.toggle('dark', dark);
    root.classList.toggle('light', !dark);
    root.setAttribute('data-appearance-mode', normalizedMode);

    document.querySelectorAll('.theme-toggle').forEach(function (toggle) {
      toggle.setAttribute('aria-checked', String(dark));
      toggle.setAttribute('data-appearance-mode', normalizedMode);
      toggle.setAttribute('title', getAppearanceLabel(normalizedMode, dark));
      toggle.setAttribute('aria-label', getAppearanceLabel(normalizedMode, dark));
    });

    window.dispatchEvent(new CustomEvent('vp:appearance-change', { detail: { dark: dark, mode: normalizedMode } }));
  }

  function applyModeWithoutTransitions(mode) {
    root.classList.add('vp-appearance-switching');
    applyMode(mode);

    window.requestAnimationFrame(function () {
      window.requestAnimationFrame(function () {
        root.classList.remove('vp-appearance-switching');
      });
    });
  }

  var mode = readMode();
  applyMode(mode);

  // Use Turbo only for explicit frame-targeted doc visits.
  if (window.Turbo && window.Turbo.session) {
    window.Turbo.session.drive = false;
  }

  function cycleMode() {
    var isDark = root.classList.contains('dark');
    var nextMode = isDark ? 'light' : 'dark';
    var systemMode = mediaQuery.matches ? 'dark' : 'light';

    mode = nextMode === systemMode ? 'auto' : nextMode;
    writeMode(mode);
    applyModeWithoutTransitions(mode);
  }

  document.querySelectorAll('.theme-toggle').forEach(function (toggle) {
    toggle.addEventListener('click', function (event) {
      if (event.altKey) {
        mode = 'auto';
        writeMode(mode);
        applyModeWithoutTransitions(mode);
        return;
      }

      cycleMode();
    });
  });

  if (typeof mediaQuery.addEventListener === 'function') {
    mediaQuery.addEventListener('change', function () {
      if (mode === 'auto') {
        applyModeWithoutTransitions('auto');
      }
    });
  }

  function formatLastUpdatedTimes(rootElement) {
    var rootNode = rootElement || document;
    var language = navigator.language || document.documentElement.getAttribute('lang') || undefined;

    rootNode.querySelectorAll('.VPLastUpdated time[data-vp-last-updated][datetime]').forEach(function (time) {
      var date = new Date(time.getAttribute('datetime'));
      if (Number.isNaN(date.getTime())) {
        return;
      }

      try {
        time.textContent = new Intl.DateTimeFormat(language, {
          dateStyle: 'medium',
          timeStyle: 'medium'
        }).format(date);

        if (language) {
          time.setAttribute('lang', language);
        }
      } catch (error) {
        // Keep the server-rendered fallback if Intl formatting is unavailable.
      }
    });
  }

  window.__vpAppearance = {
    getMode: function () {
      return mode;
    },
    setMode: function (nextMode) {
      mode = normalizeMode(nextMode);
      writeMode(mode);
      applyModeWithoutTransitions(mode);
    },
    clearMode: function () {
      mode = 'auto';
      writeMode(mode);
      applyModeWithoutTransitions(mode);
    }
  };

  var navBar = document.getElementById('vp-nav-bar');
  var sidebar = document.getElementById('vp-sidebar');
  var backdrop = document.getElementById('vp-backdrop');
  var hamburger = document.getElementById('vp-nav-hamburger');
  var localMenuButton = document.getElementById('vp-local-menu-button');
  var navScreen = document.getElementById('VPNavScreen');
  var versionSelector = document.getElementById('vp-version-selector');
  var versionButton = document.getElementById('vp-version-button');
  var versionMenu = document.getElementById('vp-version-menu');
  var navScreenVersionGroup = document.getElementById('vp-nav-screen-version-group');
  var navScreenVersionButton = document.getElementById('vp-nav-screen-version-button');
  var navScreenVersionItems = document.getElementById('vp-nav-screen-version-items');
  var extra = document.getElementById('vp-nav-extra');
  var extraButton = document.getElementById('vp-nav-extra-button');
  var extraMenu = document.getElementById('vp-nav-extra-menu');

  var navScreenOpen = false;
  var sidebarOpen = false;
  var navScreenVersionOpen = false;
  var versionOpen = false;
  var extraOpen = false;
  var bodyScrollLocked = false;
  var bodyInitialOverflow = '';
  var rootInitialOverflowY = '';

  function hasScrollableAncestor(element) {
    if (!element || element === document.body || element.nodeType !== 1) {
      return false;
    }

    var style = window.getComputedStyle(element);
    if (
      style.overflowX === 'scroll' ||
      style.overflowY === 'scroll' ||
      (style.overflowX === 'auto' && element.clientWidth < element.scrollWidth) ||
      (style.overflowY === 'auto' && element.clientHeight < element.scrollHeight)
    ) {
      return true;
    }

    return hasScrollableAncestor(element.parentElement);
  }

  function preventBodyTouchMove(event) {
    if (hasScrollableAncestor(event.target)) {
      return;
    }

    if (event.touches && event.touches.length > 1) {
      return;
    }

    event.preventDefault();
  }

  function setBodyScrollLocked(locked) {
    if (locked === bodyScrollLocked) {
      return;
    }

    if (locked) {
      bodyInitialOverflow = document.body.style.overflow;
      rootInitialOverflowY = root.style.overflowY;
      root.style.overflowY = 'hidden';
      document.body.style.overflow = 'hidden';
      document.body.addEventListener('touchmove', preventBodyTouchMove, { passive: false });
      bodyScrollLocked = true;
      return;
    }

    root.style.overflowY = rootInitialOverflowY;
    document.body.style.overflow = bodyInitialOverflow;
    document.body.removeEventListener('touchmove', preventBodyTouchMove);
    bodyScrollLocked = false;
  }

  function setVersionOpen(open) {
    if (!versionSelector || !versionButton || !versionMenu) {
      versionOpen = false;
      return;
    }

    versionOpen = open;
    versionSelector.classList.toggle('open', open);
    versionButton.setAttribute('aria-expanded', String(open));
    versionMenu.hidden = !open;
  }

  function setExtraOpen(open) {
    if (!extra || !extraButton || !extraMenu) {
      extraOpen = false;
      return;
    }

    extraOpen = open;
    extra.classList.toggle('open', open);
    extraButton.setAttribute('aria-expanded', String(open));
    extraMenu.setAttribute('aria-hidden', String(!open));
  }

  function setNavScreenVersionOpen(open) {
    if (!navScreenVersionGroup || !navScreenVersionButton || !navScreenVersionItems) {
      navScreenVersionOpen = false;
      return;
    }

    navScreenVersionOpen = !!open;
    navScreenVersionGroup.classList.toggle('open', navScreenVersionOpen);
    navScreenVersionButton.setAttribute('aria-expanded', String(navScreenVersionOpen));
    navScreenVersionItems.setAttribute('aria-hidden', String(!navScreenVersionOpen));
  }

  if (versionButton && versionMenu) {
    versionButton.addEventListener('click', function (event) {
      event.preventDefault();
      event.stopPropagation();
      if (extraOpen) {
        setExtraOpen(false);
      }
      setVersionOpen(!versionOpen);
    });

    versionMenu.addEventListener('click', function (event) {
      if (event.target.closest('a')) {
        setVersionOpen(false);
      }
    });

    document.addEventListener('click', function (event) {
      if (versionOpen && versionSelector && !versionSelector.contains(event.target)) {
        setVersionOpen(false);
      }
    });
  }

  if (extraButton && extraMenu) {
    extraButton.addEventListener('click', function (event) {
      event.preventDefault();
      event.stopPropagation();
      if (versionOpen) {
        setVersionOpen(false);
      }
      setExtraOpen(!extraOpen);
    });

    extraMenu.addEventListener('click', function (event) {
      if (event.target.closest('a') && !event.target.closest('.theme-toggle')) {
        setExtraOpen(false);
      }
    });

    document.addEventListener('click', function (event) {
      if (extraOpen && extra && !extra.contains(event.target)) {
        setExtraOpen(false);
      }
    });
  }

  if (navScreenVersionButton) {
    navScreenVersionButton.addEventListener('click', function (event) {
      event.preventDefault();
      event.stopPropagation();
      setNavScreenVersionOpen(!navScreenVersionOpen);
    });
  }

  function formatExactCount(value) {
    try {
      return new Intl.NumberFormat('en-US').format(value);
    } catch (error) {
      return String(value);
    }
  }

  function formatCompactCount(value) {
    var count = Number(value);
    if (!Number.isFinite(count) || count < 0) {
      return null;
    }

    if (count >= 1000000) {
      var millions = (count / 1000000).toFixed(count >= 10000000 ? 0 : 1);
      return millions.replace(/\.0$/, '') + 'M';
    }

    if (count >= 1000) {
      var thousands = (count / 1000).toFixed(count >= 100000 ? 0 : 1);
      return thousands.replace(/\.0$/, '') + 'k';
    }

    return String(Math.round(count));
  }

  function setGitHubStarCount(button, value) {
    if (!button) {
      return;
    }

    var countElement = button.querySelector('.VPNavBarStarCount, .VPMetricButtonCount[data-vp-github-star-count]');
    if (!countElement) {
      return;
    }

    var metricButton = button.classList.contains('VPMetricButton');
    var formatted = metricButton ? formatExactCount(value) : formatCompactCount(value);
    if (!formatted) {
      return;
    }

    countElement.textContent = formatted;
    countElement.hidden = false;

    if (metricButton) {
      var repository = button.getAttribute('data-github-star-repo');
      button.title = formatted + ' GitHub stars';
      if (repository) {
        button.setAttribute('aria-label', 'Star ' + repository + ' on GitHub: ' + formatted + ' stars');
      }
    }
  }

  var metricCacheTtlMs = 6 * 60 * 60 * 1000;
  var pendingMetricFetches = {};

  function readCachedMetric(key) {
    if (!window.localStorage) {
      return null;
    }

    try {
      var raw = localStorage.getItem(key);
      if (!raw) {
        return null;
      }

      var entry = JSON.parse(raw);
      if (!entry || !Number.isFinite(entry.value) || !Number.isFinite(entry.ts)) {
        return null;
      }

      if (Date.now() - entry.ts > metricCacheTtlMs) {
        return null;
      }

      return entry.value;
    } catch (error) {
      return null;
    }
  }

  function writeCachedMetric(key, value) {
    if (!window.localStorage) {
      return;
    }

    try {
      localStorage.setItem(key, JSON.stringify({ value: value, ts: Date.now() }));
    } catch (error) {
      // Ignore storage errors.
    }
  }

  function loadMetric(key, fetcher) {
    var cached = readCachedMetric(key);
    if (cached !== null) {
      return Promise.resolve(cached);
    }

    if (!pendingMetricFetches[key]) {
      pendingMetricFetches[key] = fetcher()
        .then(function (value) {
          writeCachedMetric(key, value);
          return value;
        })
        .catch(function () {
          // Keep the button visible without count if API lookup fails.
          return null;
        });
    }

    return pendingMetricFetches[key];
  }

  function loadGitHubStarCount(button) {
    if (!button || button.getAttribute('data-github-star-show-count') === 'false') {
      return;
    }

    var repository = button.getAttribute('data-github-star-repo');
    if (!repository) {
      return;
    }

    loadMetric('vp-metric:github-stars:' + repository, function () {
      var apiRepository = repository
        .split('/')
        .map(function (segment) {
          return encodeURIComponent(segment);
        })
        .join('/');

      return fetch('https://api.github.com/repos/' + apiRepository, {
        headers: { Accept: 'application/vnd.github+json' }
      })
        .then(function (response) {
          if (!response.ok) {
            throw new Error('GitHub API request failed');
          }
          return response.json();
        })
        .then(function (data) {
          if (!data || typeof data.stargazers_count !== 'number') {
            throw new Error('GitHub response missing stargazers_count');
          }
          return data.stargazers_count;
        });
    }).then(function (stars) {
      if (stars !== null) {
        setGitHubStarCount(button, stars);
      }
    });
  }

  function setRubyGemsDownloads(button, value) {
    if (!button) {
      return;
    }

    var countElement = button.querySelector('.VPMetricButtonCount[data-vp-rubygems-downloads-count]');
    if (!countElement) {
      return;
    }

    var formatted = formatCompactCount(value);
    if (!formatted) {
      return;
    }

    var exactCount = formatExactCount(value);
    var textElement = button.querySelector('.VPMetricButtonText');
    countElement.textContent = formatted + ' downloads';
    countElement.hidden = false;
    if (textElement) {
      textElement.hidden = true;
    }

    var label = button.getAttribute('data-rubygems-downloads-label') || 'View gem downloads';
    button.title = exactCount + ' downloads on RubyGems';
    button.setAttribute('aria-label', label + ': ' + exactCount + ' downloads');
  }

  function loadRubyGemsDownloads(button) {
    if (!button || button.getAttribute('data-rubygems-downloads-show-count') === 'false') {
      return;
    }

    var gemName = button.getAttribute('data-rubygems-downloads-gem');
    if (!gemName) {
      return;
    }

    loadMetric('vp-metric:rubygems-downloads:' + gemName, function () {
      return fetch('https://rubygems.org/api/v1/gems/' + encodeURIComponent(gemName) + '.json', {
        credentials: 'omit',
        headers: { Accept: 'application/json' }
      })
        .then(function (response) {
          if (!response.ok) {
            throw new Error('RubyGems API request failed');
          }
          return response.json();
        })
        .then(function (data) {
          var downloads = Number(data && data.downloads);
          if (!Number.isFinite(downloads)) {
            throw new Error('RubyGems response missing downloads');
          }
          return downloads;
        });
    }).then(function (downloads) {
      if (downloads !== null) {
        setRubyGemsDownloads(button, downloads);
      }
    });
  }

  function loadMetricButtons(rootElement) {
    var rootNode = rootElement || document;

    rootNode.querySelectorAll('.VPNavBarStarLink[data-github-star-repo], .VPMetricButton[data-github-star-repo]').forEach(function (button) {
      loadGitHubStarCount(button);
    });

    rootNode.querySelectorAll('.VPMetricButton[data-rubygems-downloads-gem]').forEach(function (button) {
      loadRubyGemsDownloads(button);
    });
  }

  loadMetricButtons(document);
  formatLastUpdatedTimes(document);

  function syncMobileMenus() {
    if (sidebar) {
      sidebar.classList.toggle('open', sidebarOpen);
    }

    if (navBar) {
      navBar.classList.toggle('screen-open', navScreenOpen);
    }

    if (backdrop) {
      backdrop.classList.toggle('is-active', sidebarOpen);
    }

    if (hamburger) {
      hamburger.classList.toggle('active', navScreenOpen);
      hamburger.setAttribute('aria-expanded', String(navScreenOpen));
    }

    if (localMenuButton) {
      localMenuButton.setAttribute('aria-expanded', String(sidebarOpen));
    }

    if (navScreen) {
      navScreen.hidden = !navScreenOpen;
    }

    document.body.classList.toggle('vp-nav-screen-open', navScreenOpen);
    document.body.classList.toggle('vp-sidebar-open', sidebarOpen);
    setBodyScrollLocked(navScreenOpen || sidebarOpen);
  }

  function closeMobileMenus() {
    if (navScreenVersionOpen) {
      setNavScreenVersionOpen(false);
    }
    navScreenOpen = false;
    sidebarOpen = false;
    syncMobileMenus();
  }

  function setNavScreenOpen(open) {
    navScreenOpen = !!open;
    if (navScreenOpen) {
      sidebarOpen = false;
    } else if (navScreenVersionOpen) {
      setNavScreenVersionOpen(false);
    }
    if (navScreenOpen && extraOpen) {
      setExtraOpen(false);
    }
    if (navScreenOpen && versionOpen) {
      setVersionOpen(false);
    }
    syncMobileMenus();
  }

  function setSidebarOpen(open) {
    sidebarOpen = !!open;
    if (sidebarOpen) {
      if (navScreenVersionOpen) {
        setNavScreenVersionOpen(false);
      }
      navScreenOpen = false;
    }
    if (sidebarOpen && extraOpen) {
      setExtraOpen(false);
    }
    if (sidebarOpen && versionOpen) {
      setVersionOpen(false);
    }
    syncMobileMenus();
  }

  function toggleNavScreen() {
    setNavScreenOpen(!navScreenOpen);
  }

  function toggleSidebar() {
    setSidebarOpen(!sidebarOpen);
  }

  if (hamburger) {
    hamburger.addEventListener('click', toggleNavScreen);
  }

  if (localMenuButton) {
    localMenuButton.addEventListener('click', toggleSidebar);
  }

  if (backdrop) {
    backdrop.addEventListener('click', function () {
      closeMobileMenus();
    });
  }

  if (navScreen) {
    navScreen.addEventListener('click', function (event) {
      if (event.target === navScreen || event.target.closest('a')) {
        setNavScreenOpen(false);
      }
    });
  }

  syncMobileMenus();

  window.addEventListener('resize', function () {
    if (window.innerWidth >= 768 && navScreenOpen) {
      setNavScreenOpen(false);
    }
    if (window.innerWidth >= 960 && sidebarOpen) {
      setSidebarOpen(false);
    }
    if (window.innerWidth < 768 && versionOpen) {
      setVersionOpen(false);
    }
    if ((window.innerWidth < 768 || window.innerWidth >= 1280) && extraOpen) {
      setExtraOpen(false);
    }
  });

  function syncNavTop() {
    if (!navBar) {
      return;
    }
    navBar.classList.toggle('top', window.scrollY < 4);
  }

  syncNavTop();
  window.addEventListener('scroll', syncNavTop, { passive: true });

  function setSidebarSectionCollapsed(section, collapsed) {
    section.classList.toggle('collapsed', collapsed);

    var item = section.querySelector(':scope > .item');
    var caret = section.querySelector(':scope > .item .caret');
    var expanded = String(!collapsed);

    if (item) {
      item.setAttribute('aria-expanded', expanded);
    }

    if (caret) {
      caret.setAttribute('aria-expanded', expanded);
    }
  }

  document.querySelectorAll('.VPSidebarItem.collapsible').forEach(function (section) {
    var item = section.querySelector(':scope > .item');
    var caret = section.querySelector(':scope > .item .caret');

    function toggleSection() {
      setSidebarSectionCollapsed(section, !section.classList.contains('collapsed'));
    }

    if (item) {
      item.addEventListener('click', function (event) {
        if (event.target.closest('a')) {
          return;
        }
        toggleSection();
      });

      item.addEventListener('keydown', function (event) {
        if (event.target.closest('a')) {
          return;
        }

        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          toggleSection();
        }
      });
    }

    if (caret) {
      caret.addEventListener('click', function (event) {
        event.stopPropagation();
        toggleSection();
      });
      caret.addEventListener('keydown', function (event) {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          event.stopPropagation();
          toggleSection();
        }
      });
    }
  });

  var searchRoot = document.getElementById('vp-search');
  var searchButton = document.getElementById('vp-search-button');
  var searchBackdrop = document.getElementById('vp-search-backdrop');
  var searchInput = document.getElementById('vp-search-input');
  var searchResults = document.getElementById('vp-search-results');
  var searchIndexUrl = searchRoot ? searchRoot.getAttribute('data-search-index-url') : null;
  var searchFrameTarget = searchRoot ? searchRoot.getAttribute('data-search-frame-target') : '';

  var searchOpen = false;
  var searchItems = [];
  var searchIndexPromise = null;
  var activeResultIndex = -1;

  function loadSearchIndex() {
    if (!searchIndexUrl) {
      return Promise.resolve([]);
    }

    if (searchItems.length > 0) {
      return Promise.resolve(searchItems);
    }

    if (searchIndexPromise) {
      return searchIndexPromise;
    }

    searchIndexPromise = fetch(searchIndexUrl, { credentials: 'same-origin' })
      .then(function (response) {
        if (!response.ok) {
          throw new Error('Search index load failed');
        }
        return response.json();
      })
      .then(function (items) {
        if (Array.isArray(items)) {
          searchItems = items;
        }
        return searchItems;
      })
      .catch(function () {
        searchItems = [];
        return searchItems;
      });

    return searchIndexPromise;
  }

  function escapeHtml(value) {
    return String(value || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  function escapeRegex(value) {
    return String(value || '').replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  function highlightSearchMatches(value, terms) {
    var text = String(value || '');
    var uniqueTerms = Array.from(new Set(terms))
      .filter(Boolean)
      .sort(function (a, b) {
        return b.length - a.length;
      });

    if (!text || !uniqueTerms.length) {
      return escapeHtml(text);
    }

    var pattern = new RegExp('(' + uniqueTerms.map(escapeRegex).join('|') + ')', 'gi');
    var html = '';
    var lastIndex = 0;
    var match;

    while ((match = pattern.exec(text)) !== null) {
      html += escapeHtml(text.slice(lastIndex, match.index));
      html += '<mark>' + escapeHtml(match[0]) + '</mark>';
      lastIndex = pattern.lastIndex;
    }

    html += escapeHtml(text.slice(lastIndex));
    return html;
  }

  function scoreSearchItem(item, terms, query) {
    var title = String(item.title || '').toLowerCase();
    var content = String(item.content || '').toLowerCase();

    var score = 0;
    for (var i = 0; i < terms.length; i += 1) {
      var term = terms[i];
      var titleIndex = title.indexOf(term);
      var contentIndex = content.indexOf(term);

      if (titleIndex < 0 && contentIndex < 0) {
        return -1;
      }

      if (titleIndex >= 0) {
        score += titleIndex === 0 ? 100 : 40;
      }

      if (contentIndex >= 0) {
        score += contentIndex < 120 ? 20 : 10;
      }
    }

    if (title.indexOf(query) >= 0) {
      score += 60;
    }

    return score;
  }

  function buildSnippet(item, terms) {
    var content = String(item.content || '').replace(/\s+/g, ' ').trim();
    if (!content) {
      return '';
    }

    var lower = content.toLowerCase();
    var index = -1;

    for (var i = 0; i < terms.length; i += 1) {
      var hit = lower.indexOf(terms[i]);
      if (hit >= 0 && (index < 0 || hit < index)) {
        index = hit;
      }
    }

    if (index < 0) {
      index = 0;
    }

    var start = Math.max(0, index - 60);
    var end = Math.min(content.length, start + 180);
    var snippet = content.slice(start, end).trim();

    if (start > 0) {
      snippet = '... ' + snippet;
    }

    if (end < content.length) {
      snippet += ' ...';
    }

    return snippet;
  }

  function setActiveSearchResult(index) {
    if (!searchResults) {
      return;
    }

    var links = Array.from(searchResults.querySelectorAll('.VPSearchResult'));
    if (!links.length) {
      activeResultIndex = -1;
      return;
    }

    activeResultIndex = Math.max(0, Math.min(index, links.length - 1));

    links.forEach(function (link, linkIndex) {
      var active = linkIndex === activeResultIndex;
      link.classList.toggle('active', active);
      if (active) {
        link.scrollIntoView({ block: 'nearest' });
      }
    });
  }

  function renderSearchResults(query) {
    if (!searchResults) {
      return;
    }

    var normalized = String(query || '').trim().toLowerCase();

    if (!normalized) {
      searchResults.innerHTML = '<p class="VPSearchEmpty">Type to search documentation</p>';
      activeResultIndex = -1;
      return;
    }

    var terms = normalized.split(/\s+/).filter(Boolean);

    var ranked = searchItems
      .map(function (item) {
        return {
          item: item,
          score: scoreSearchItem(item, terms, normalized)
        };
      })
      .filter(function (entry) {
        return entry.score >= 0;
      })
      .sort(function (a, b) {
        return b.score - a.score;
      })
      .slice(0, 20);

    if (!ranked.length) {
      searchResults.innerHTML = '<p class="VPSearchEmpty">No matches found</p>';
      activeResultIndex = -1;
      return;
    }

    var html = ranked
      .map(function (entry) {
        var item = entry.item;
        var title = highlightSearchMatches(item.title || item.url || 'Untitled', terms);
        var url = escapeHtml(item.url || '/');
        var snippet = highlightSearchMatches(buildSnippet(item, terms), terms);
        var turboAttributes = searchFrameTarget && url !== '/'
          ? ' data-turbo="true" data-turbo-frame="' + escapeHtml(searchFrameTarget) + '" data-turbo-action="advance"'
          : '';

        return (
          '<a class="VPSearchResult" role="option" href="' +
          url +
          '"' +
          turboAttributes +
          '>' +
          '<span class="title">' +
          title +
          '</span>' +
          '<span class="snippet">' +
          snippet +
          '</span>' +
          '</a>'
        );
      })
      .join('');

    searchResults.innerHTML = html;
    setActiveSearchResult(0);
  }

  function closeSearch() {
    if (!searchRoot) {
      return;
    }

    searchOpen = false;
    searchRoot.hidden = true;
    document.body.classList.remove('vp-search-open');

    if (searchButton) {
      searchButton.setAttribute('aria-expanded', 'false');
    }
  }

  function openSearch() {
    if (!searchRoot || !searchInput) {
      return;
    }

    if (versionOpen) {
      setVersionOpen(false);
    }
    if (extraOpen) {
      setExtraOpen(false);
    }

    if (navScreenOpen || sidebarOpen) {
      closeMobileMenus();
    }

    searchOpen = true;
    searchRoot.hidden = false;
    document.body.classList.add('vp-search-open');

    if (searchButton) {
      searchButton.setAttribute('aria-expanded', 'true');
    }

    loadSearchIndex().then(function () {
      renderSearchResults(searchInput.value);
    });

    window.requestAnimationFrame(function () {
      searchInput.focus();
      searchInput.select();
    });
  }

  if (searchButton) {
    searchButton.addEventListener('click', function () {
      if (searchOpen) {
        closeSearch();
      } else {
        openSearch();
      }
    });
  }

  if (searchBackdrop) {
    searchBackdrop.addEventListener('click', closeSearch);
  }

  if (searchResults) {
    searchResults.addEventListener('click', function (event) {
      if (event.target.closest('a')) {
        closeSearch();
      }
    });
  }

  if (searchInput) {
    searchInput.addEventListener('input', function (event) {
      renderSearchResults(event.target.value);
    });

    searchInput.addEventListener('keydown', function (event) {
      if (event.key === 'ArrowDown') {
        event.preventDefault();
        setActiveSearchResult(activeResultIndex + 1);
        return;
      }

      if (event.key === 'ArrowUp') {
        event.preventDefault();
        setActiveSearchResult(activeResultIndex - 1);
        return;
      }

      if (event.key === 'Enter') {
        var links = searchResults ? Array.from(searchResults.querySelectorAll('.VPSearchResult')) : [];
        if (links.length && activeResultIndex >= 0) {
          links[activeResultIndex].click();
        }
      }
    });
  }

  function shouldOpenSearchFromKeyboard(event) {
    if (event.defaultPrevented || event.metaKey || event.ctrlKey || event.altKey || event.shiftKey) {
      return false;
    }

    var target = event.target;
    if (!target) {
      return true;
    }

    var tagName = String(target.tagName || '').toLowerCase();
    if (tagName === 'input' || tagName === 'textarea' || tagName === 'select') {
      return false;
    }

    if (target.isContentEditable) {
      return false;
    }

    return event.key === '/';
  }

  document.addEventListener('keydown', function (event) {
    if (event.key === 'Escape') {
      if (searchOpen) {
        event.preventDefault();
        closeSearch();
        return;
      }

      if (extraOpen) {
        event.preventDefault();
        setExtraOpen(false);
        return;
      }

      if (versionOpen) {
        event.preventDefault();
        setVersionOpen(false);
        return;
      }

      closeMobileMenus();
      return;
    }

    var isSearchShortcut = (event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k';
    if (isSearchShortcut) {
      event.preventDefault();
      if (versionOpen) {
        setVersionOpen(false);
      }
      openSearch();
      return;
    }

    if (shouldOpenSearchFromKeyboard(event)) {
      event.preventDefault();
      if (versionOpen) {
        setVersionOpen(false);
      }
      openSearch();
    }
  });

  function writeToClipboard(text) {
    if (navigator.clipboard && typeof navigator.clipboard.writeText === 'function') {
      return navigator.clipboard.writeText(text);
    }

    return new Promise(function (resolve, reject) {
      try {
        var textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.setAttribute('readonly', '');
        textarea.style.position = 'fixed';
        textarea.style.top = '-9999px';
        document.body.appendChild(textarea);
        textarea.select();

        var copied = document.execCommand('copy');
        document.body.removeChild(textarea);

        if (copied) {
          resolve();
        } else {
          reject(new Error('Copy command failed'));
        }
      } catch (error) {
        reject(error);
      }
    });
  }

  var fileIconAliases = {
    rb: 'ruby',
    rake: 'ruby',
    erb: 'ruby',
    ruby: 'ruby',

    js: 'javascript',
    mjs: 'javascript',
    cjs: 'javascript',
    jsx: 'javascript',
    javascript: 'javascript',

    ts: 'typescript',
    mts: 'typescript',
    cts: 'typescript',
    tsx: 'typescript',
    typescript: 'typescript',

    json: 'json',
    jsonc: 'json',
    json5: 'json',

    md: 'markdown',
    markdown: 'markdown',
    mdx: 'markdown',

    html: 'html',
    htm: 'html',

    css: 'css',
    scss: 'css',
    sass: 'css',
    less: 'css',

    vue: 'vue',
    yml: 'yaml',
    yaml: 'yaml',
    toml: 'toml',

    sh: 'shell',
    bash: 'shell',
    zsh: 'shell',
    fish: 'shell',
    shell: 'shell',

    py: 'python',
    python: 'python',

    go: 'go',
    golang: 'go',
    rs: 'rust',
    rust: 'rust',
    java: 'java',

    kt: 'kotlin',
    kts: 'kotlin',
    kotlin: 'kotlin',

    php: 'php',
    sql: 'sql',
    xml: 'xml',

    docker: 'docker',
    dockerfile: 'docker',
    containerfile: 'docker',

    make: 'make',
    makefile: 'make',

    env: 'env',
    '.env': 'env',

    txt: 'text',
    text: 'text',
    plaintext: 'text'
  };

  var specialFileIconAliases = {
    gemfile: 'ruby',
    rakefile: 'ruby',
    '.ruby-version': 'ruby',
    dockerfile: 'docker',
    containerfile: 'docker',
    makefile: 'make',
    '.env': 'env'
  };

  function normalizeFileIconKey(value) {
    var key = (value || '').toLowerCase().trim();
    return fileIconAliases[key] || '';
  }

  function inferFileIconFromTitle(title) {
    var raw = (title || '').trim().toLowerCase();
    if (!raw) {
      return '';
    }

    var clean = raw.split(/[?#]/)[0];
    var base = clean.split('/').pop();
    if (!base) {
      return '';
    }

    var directMatch = specialFileIconAliases[base];
    if (directMatch) {
      return directMatch;
    }

    if (base.indexOf('.env.') === 0) {
      return 'env';
    }

    var dotIndex = base.lastIndexOf('.');
    if (dotIndex > 0 && dotIndex < base.length - 1) {
      var ext = base.slice(dotIndex + 1);
      return normalizeFileIconKey(ext);
    }

    return normalizeFileIconKey(base);
  }

  function addCopyButtons() {
    document.querySelectorAll('.vp-doc div.highlighter-rouge').forEach(function (block) {
      var code = block.querySelector('pre code');
      if (!code) {
        return;
      }

      var button = block.querySelector(':scope > button.copy');
      if (!button) {
        button = document.createElement('button');
        button.className = 'copy';
        button.type = 'button';
        block.insertBefore(button, block.firstChild);
      }
      button.setAttribute('aria-label', 'Copy code');
      button.setAttribute('title', 'Copy code');

      var language = '';
      Array.from(block.classList).forEach(function (className) {
        if (!language && className.indexOf('language-') === 0) {
          language = className.slice(9).trim().toLowerCase();
        }
      });
      if (language === 'plaintext') {
        language = 'text';
      }

      var languageTag = block.querySelector(':scope > span.lang');
      if (!languageTag && language) {
        languageTag = document.createElement('span');
        languageTag.className = 'lang';
        languageTag.textContent = language;
        if (button.nextSibling) {
          block.insertBefore(languageTag, button.nextSibling);
        } else {
          block.appendChild(languageTag);
        }
      }

      var title = block.getAttribute('data-title') || '';
      if (!title) {
        var previous = block.previousElementSibling;
        if (previous && previous.classList.contains('vp-code-title')) {
          title = previous.textContent ? previous.textContent.trim() : '';
          previous.remove();
        }
      }

      if (title && (!block.parentElement || !block.parentElement.classList.contains('vp-code-block-title'))) {
        var wrapper = document.createElement('div');
        wrapper.className = 'vp-code-block-title';

        var iconKey = inferFileIconFromTitle(title) || normalizeFileIconKey(language) || 'default';
        var titleBar = document.createElement('div');
        titleBar.className = 'vp-code-block-title-bar';

        var titleText = document.createElement('span');
        titleText.className = 'vp-code-block-title-text';
        titleText.setAttribute('data-title', title);
        if (iconKey) {
          titleText.setAttribute('data-icon', iconKey);
        }
        titleText.textContent = title;

        titleBar.appendChild(titleText);

        var parent = block.parentNode;
        if (parent) {
          parent.insertBefore(wrapper, block);
          wrapper.appendChild(titleBar);
          wrapper.appendChild(block);
          block.classList.add('has-title');
        }
      }

      button.addEventListener('click', function () {
        var text = code.textContent || '';

        writeToClipboard(text)
          .then(function () {
            button.classList.add('copied');
            if (button._copyTimeout) {
              window.clearTimeout(button._copyTimeout);
            }
            button._copyTimeout = window.setTimeout(function () {
              button.classList.remove('copied');
            }, 2000);
          })
          .catch(function () {
            // Ignore copy errors so UI remains interactive.
          });
      });
    });
  }

  addCopyButtons();

  // Copy page as Markdown - split button with dropdown
  function copyPageMarkdown(btn) {
    if (!btn) return;

    var textarea = document.querySelector('.vp-raw-markdown');
    if (!textarea) return;

    var icon = btn.querySelector('.copy-md-icon');
    var label = btn.querySelector('.copy-md-label');
    function setCopied(copied) {
      btn.classList.toggle('copied', copied);
      if (icon) {
        icon.classList.toggle('vpi-copy', !copied);
        icon.classList.toggle('vpi-check', copied);
      }
      if (label) label.textContent = copied ? 'Copied' : 'Copy page';
    }

    writeToClipboard(textarea.value)
      .then(function () {
        setCopied(true);
        if (btn._copyTimeout) window.clearTimeout(btn._copyTimeout);
        btn._copyTimeout = window.setTimeout(function () {
          setCopied(false);
        }, 2000);
      })
      .catch(function () {});
  }

  var copyMdBtn = document.querySelector('.copy-md-btn');
  var toggle = document.querySelector('.copy-md-toggle');
  var dropdown = document.querySelector('.copy-md-dropdown');
  var dropdownCopy = dropdown ? dropdown.querySelector('[data-action="copy"]') : null;
  var dropdownView = dropdown ? dropdown.querySelector('[data-action="view-markdown"]') : null;

  function setCopyPageDropdownOpen(open) {
    if (!dropdown || !toggle) {
      return;
    }

    if (dropdown.hidden) {
      dropdown.hidden = false;
    }

    dropdown.setAttribute('aria-hidden', String(!open));
    toggle.setAttribute('aria-expanded', String(open));
  }

  function isCopyPageDropdownOpen() {
    return !!(dropdown && dropdown.getAttribute('aria-hidden') === 'false');
  }

  function bindCopyPageControls() {
    if (dropdown) {
      if (dropdown.hidden) {
        dropdown.hidden = false;
      }
      if (!dropdown.hasAttribute('aria-hidden')) {
        dropdown.setAttribute('aria-hidden', 'true');
      }
    }

    if (copyMdBtn && !copyMdBtn.hasAttribute('data-vp-bound')) {
      copyMdBtn.setAttribute('data-vp-bound', 'true');
      copyMdBtn.addEventListener('click', function () {
        copyPageMarkdown(copyMdBtn);
      });
    }

    if (toggle && dropdown && !toggle.hasAttribute('data-vp-bound')) {
      toggle.setAttribute('data-vp-bound', 'true');
      toggle.addEventListener('click', function (e) {
        e.stopPropagation();
        setCopyPageDropdownOpen(!isCopyPageDropdownOpen());
      });
    }

    dropdownCopy = dropdown ? dropdown.querySelector('[data-action="copy"]') : null;
    if (dropdownCopy && !dropdownCopy.hasAttribute('data-vp-bound')) {
      dropdownCopy.setAttribute('data-vp-bound', 'true');
      dropdownCopy.addEventListener('click', function () {
        setCopyPageDropdownOpen(false);
        copyPageMarkdown(copyMdBtn);
      });
    }

    dropdownView = dropdown ? dropdown.querySelector('[data-action="view-markdown"]') : null;
    if (dropdownView && !dropdownView.hasAttribute('data-vp-bound')) {
      dropdownView.setAttribute('data-vp-bound', 'true');
      dropdownView.addEventListener('click', function () {
        var url = dropdownView.getAttribute('data-url');
        setCopyPageDropdownOpen(false);
        if (url) window.open(url, '_blank', 'noopener,noreferrer');
      });
    }
  }

  bindCopyPageControls();

  document.addEventListener('click', function (e) {
    if (!dropdown || !toggle || !isCopyPageDropdownOpen()) {
      return;
    }
    if (!dropdown.contains(e.target) && !toggle.contains(e.target)) {
      setCopyPageDropdownOpen(false);
    }
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && dropdown && toggle && isCopyPageDropdownOpen()) {
      setCopyPageDropdownOpen(false);
      toggle.focus();
    }
  });

  var content = document.querySelector('.vp-doc');
  if (!content) {
    return;
  }

  function getHeadingLabel(heading) {
    var clone = heading.cloneNode(true);
    clone.querySelectorAll('.header-anchor').forEach(function (anchor) {
      anchor.remove();
    });
    return clone.textContent ? clone.textContent.trim() : heading.id;
  }

  function injectHeaderAnchors(contentRoot) {
    contentRoot.querySelectorAll('h1[id], h2[id], h3[id], h4[id], h5[id], h6[id]').forEach(function (heading) {
      if (heading.querySelector('.header-anchor')) {
        return;
      }

      var title = getHeadingLabel(heading);
      var anchor = document.createElement('a');
      anchor.className = 'header-anchor';
      anchor.href = '#' + heading.id;
      anchor.setAttribute('aria-label', 'Permalink to "' + title + '"');
      anchor.textContent = '\u200B';

      heading.appendChild(document.createTextNode(' '));
      heading.appendChild(anchor);
    });
  }

  injectHeaderAnchors(content);

  var headings = Array.from(content.querySelectorAll('h2[id], h3[id]'));
  var asideOutline = document.querySelector('.VPDocAsideOutline');
  var localNav = document.getElementById('vp-local-nav');
  var localOutlineDropdown = document.getElementById('vp-local-outline-dropdown');

  var localOutlineButton = document.getElementById('vp-local-outline-button');
  var localOutlineItems = document.querySelector('#vp-local-outline-dropdown .items');
  var localOutlineContainer = document.querySelector('#vp-local-outline-dropdown .outline .VPDocOutlineItem');
  var localTopLink = document.getElementById('vp-local-top-link');
  var returnToTopLabel = (localTopLink && localTopLink.textContent ? localTopLink.textContent.trim() : 'Return to top');

  function syncLocalOutlineViewportHeight() {
    if (!localOutlineDropdown) {
      return;
    }

    var viewportHeight = window.innerHeight;
    if (window.visualViewport && window.visualViewport.height) {
      viewportHeight = window.visualViewport.height;
    }

    localOutlineDropdown.style.setProperty('--vp-vh', String(Math.round(viewportHeight)) + 'px');
  }

  syncLocalOutlineViewportHeight();
  window.addEventListener('resize', syncLocalOutlineViewportHeight, { passive: true });
  if (window.visualViewport && typeof window.visualViewport.addEventListener === 'function') {
    window.visualViewport.addEventListener('resize', syncLocalOutlineViewportHeight, { passive: true });
  }

  function createOutlineTree(list) {
    var tree = [];
    var currentGroup = null;

    list.forEach(function (heading) {
      if (heading.tagName === 'H2') {
        currentGroup = {
          heading: heading,
          children: []
        };
        tree.push(currentGroup);
        return;
      }

      if (!currentGroup) {
        currentGroup = {
          heading: heading,
          children: []
        };
        tree.push(currentGroup);
        return;
      }

      currentGroup.children.push({
        heading: heading,
        children: []
      });
    });

    return tree;
  }

  function buildOutlineNodes(entries, isRoot) {
    var ul = document.createElement('ul');
    ul.className = 'VPDocOutlineItem ' + (isRoot ? 'root' : 'nested');

    entries.forEach(function (entry) {
      if (!entry.heading) {
        return;
      }

      var li = document.createElement('li');
      var link = document.createElement('a');
      var label = getHeadingLabel(entry.heading);

      link.className = 'outline-link';
      link.href = '#' + entry.heading.id;
      link.title = label;
      link.textContent = label;

      li.appendChild(link);

      if (entry.children && entry.children.length) {
        li.appendChild(buildOutlineNodes(entry.children, false));
      }

      ul.appendChild(li);
    });

    return ul;
  }

  function replaceOutline(selector, tree, isRoot) {
    var target = document.querySelector(selector);
    if (!target) {
      return;
    }

    target.innerHTML = '';
    var outline = buildOutlineNodes(tree, isRoot);

    while (outline.firstChild) {
      target.appendChild(outline.firstChild);
    }
  }

  var hasOutline = false;

  function rebuildOutline() {
    hasOutline = headings.length > 0;

    if (asideOutline) {
      asideOutline.classList.toggle('has-outline', hasOutline);
    }

    if (localNav) {
      localNav.classList.toggle('empty', !hasOutline);
    }

    if (localOutlineButton) {
      var menuText = localOutlineButton.querySelector('.menu-text');
      var menuIcon = localOutlineButton.querySelector('.icon');
      if (menuText) {
        var outlineLabel = document.getElementById('doc-outline-aria-label');
        if (!hasOutline) {
          menuText.textContent = returnToTopLabel;
        } else if (outlineLabel) {
          menuText.textContent = outlineLabel.textContent.trim();
        }
      }
      if (menuIcon) {
        menuIcon.style.display = hasOutline ? '' : 'none';
      }
    }

    var tree = hasOutline ? createOutlineTree(headings) : [];
    replaceOutline('.VPDocAsideOutline .VPDocOutlineItem.root', tree, true);
    replaceOutline('#vp-local-outline-dropdown .outline .VPDocOutlineItem', tree, true);
    invalidateHeadingTops();
  }

  rebuildOutline();

  var localOutlineOpen = false;
  var localOutlineTransitionTimer = null;

  function clearLocalOutlineTransition() {
    if (localOutlineTransitionTimer) {
      window.clearTimeout(localOutlineTransitionTimer);
      localOutlineTransitionTimer = null;
    }

    if (localOutlineItems) {
      localOutlineItems.classList.remove(
        'flyout-enter-active',
        'flyout-enter-from',
        'flyout-leave-active',
        'flyout-leave-to'
      );
    }
  }

  function setLocalOutlineOpen(open, animate) {
    localOutlineOpen = open;

    if (localOutlineButton) {
      localOutlineButton.classList.toggle('open', open);
      localOutlineButton.setAttribute('aria-expanded', String(open));
    }

    if (!localOutlineItems) {
      return;
    }

    clearLocalOutlineTransition();

    if (open) {
      localOutlineItems.hidden = false;
      if (animate !== false) {
        localOutlineItems.classList.add('flyout-enter-active', 'flyout-enter-from');
        window.requestAnimationFrame(function () {
          if (!localOutlineOpen || !localOutlineItems) {
            return;
          }

          localOutlineItems.classList.remove('flyout-enter-from');
          localOutlineTransitionTimer = window.setTimeout(function () {
            if (localOutlineItems) {
              localOutlineItems.classList.remove('flyout-enter-active');
            }
            localOutlineTransitionTimer = null;
          }, 200);
        });
      }
      return;
    }

    if (animate === false || localOutlineItems.hidden) {
      localOutlineItems.hidden = true;
      return;
    }

    localOutlineItems.classList.add('flyout-leave-active');
    window.requestAnimationFrame(function () {
      if (localOutlineOpen || !localOutlineItems) {
        return;
      }

      localOutlineItems.classList.add('flyout-leave-to');
      localOutlineTransitionTimer = window.setTimeout(function () {
        if (localOutlineItems && !localOutlineOpen) {
          localOutlineItems.hidden = true;
          localOutlineItems.classList.remove('flyout-leave-active', 'flyout-leave-to');
        }
        localOutlineTransitionTimer = null;
      }, 150);
    });
  }

  function closeLocalOutline() {
    setLocalOutlineOpen(false, true);
  }

  if (localOutlineButton) {
    localOutlineButton.setAttribute('aria-expanded', 'false');
    if (localOutlineItems && localOutlineItems.id) {
      localOutlineButton.setAttribute('aria-controls', localOutlineItems.id);
    }

    localOutlineButton.addEventListener('click', function () {
      if (!hasOutline) {
        window.scrollTo({ top: 0, left: 0, behavior: 'smooth' });
        return;
      }

      setLocalOutlineOpen(!localOutlineOpen, true);
    });
  }

  if (localTopLink) {
    localTopLink.addEventListener('click', function (event) {
      event.preventDefault();
      closeLocalOutline();
      window.scrollTo({ top: 0, left: 0, behavior: 'smooth' });
    });
  }

  document.addEventListener('click', function (event) {
    if (!localOutlineDropdown || !localOutlineOpen) {
      return;
    }
    if (!localOutlineDropdown.contains(event.target)) {
      closeLocalOutline();
    }
  });

  if (localOutlineContainer) {
    localOutlineContainer.addEventListener('click', function (event) {
      if (event.target.classList.contains('outline-link')) {
        closeLocalOutline();
      }
    });
  }

  var marker = document.getElementById('vp-outline-marker');

  // Aligns the marker with the active link, compensating for the outline title
  // row above the link list (values lifted from VitePress's outline marker).
  var outlineMarkerLinkOffset = 39;
  var outlineMarkerRestingTop = 33;

  function getConfiguredScrollOffset() {
    var bodyScrollOffset = document.body ? document.body.getAttribute('data-vp-scroll-offset') : null;
    var offset = bodyScrollOffset ? parseFloat(bodyScrollOffset) : NaN;
    if (!Number.isNaN(offset)) {
      return offset;
    }
    return 134;
  }

  function getHashTarget(hash) {
    if (!hash) {
      return null;
    }

    var id = hash.slice(1);
    try {
      id = decodeURIComponent(id);
    } catch (error) {
      id = hash.slice(1);
    }

    return document.getElementById(id);
  }

  function scrollToHash(hash, smooth) {
    var target = getHashTarget(hash);
    if (!target) {
      return false;
    }

    var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    var behavior = 'auto';
    if (!reduceMotion && smooth && Math.abs(target.getBoundingClientRect().top) <= window.innerHeight) {
      behavior = 'smooth';
    }

    target.scrollIntoView({ block: 'start', inline: 'nearest', behavior: behavior });

    target.focus({ preventScroll: true });
    if (document.activeElement === target || target.hasAttribute('tabindex')) {
      return true;
    }

    var restoreTabindex = function () {
      target.removeAttribute('tabindex');
      target.removeEventListener('blur', restoreTabindex);
    };

    target.setAttribute('tabindex', '-1');
    target.addEventListener('blur', restoreTabindex);
    target.focus({ preventScroll: true });
    if (document.activeElement !== target) {
      restoreTabindex();
    }

    return true;
  }

  function getSamePageHash(link) {
    if (!link) {
      return null;
    }

    var href = link.getAttribute('href');
    if (!href || href === '#') {
      return null;
    }

    if (href.charAt(0) === '#') {
      return href;
    }

    var url;
    try {
      url = new URL(href, window.location.href);
    } catch (error) {
      return null;
    }

    if (url.origin !== window.location.origin ||
      normalizePathname(url.pathname) !== normalizePathname(window.location.pathname) ||
      url.search !== window.location.search ||
      !url.hash) {
      return null;
    }

    return url.hash;
  }

  function handleHashLinkClick(event) {
    if (event.defaultPrevented || (typeof event.button === 'number' && event.button !== 0) ||
      event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
      return;
    }

    var link = event.currentTarget;
    if (!link) {
      return;
    }

    var target = link.getAttribute('target');
    if (target && target !== '_self') {
      return;
    }

    var hash = getSamePageHash(link);
    if (!hash || !getHashTarget(hash)) {
      return;
    }

    event.preventDefault();

    if (window.history && typeof window.history.pushState === 'function') {
      if (window.location.hash === hash) {
        scrollToHash(hash, true);
        return;
      }
      window.history.pushState(null, '', hash);
    } else {
      window.location.hash = hash;
    }

    scrollToHash(hash, true);
  }

  function bindHashLinkHandlers() {
    document.querySelectorAll('.outline-link, .vp-doc a[href]').forEach(function (link) {
      if (link.hasAttribute('data-vp-hash-bound') || !getSamePageHash(link)) {
        return;
      }
      link.setAttribute('data-vp-hash-bound', 'true');
      link.addEventListener('click', handleHashLinkClick);
    });
  }

  bindHashLinkHandlers();

  if (window.location.hash) {
    window.requestAnimationFrame(function () {
      scrollToHash(window.location.hash, false);
    });
  }

  window.addEventListener('hashchange', function () {
    if (window.location.hash) {
      scrollToHash(window.location.hash, false);
    }
  });

  function getAbsoluteTop(element) {
    var offsetTop = 0;
    var current = element;

    while (current && current !== document.body) {
      offsetTop += current.offsetTop;
      current = current.offsetParent;
    }

    if (!current) {
      return NaN;
    }

    return offsetTop;
  }

  function activateOutlineHash(activeHash) {
    document.querySelectorAll('.outline-link').forEach(function (link) {
      var isActive = activeHash !== null && link.getAttribute('href') === activeHash;
      link.classList.toggle('active', isActive);
    });

    if (!marker) {
      return;
    }

    var activeAsideLink = document.querySelector('.VPDocAsideOutline .outline-link.active');
    if (activeAsideLink) {
      marker.style.top = String(activeAsideLink.offsetTop + outlineMarkerLinkOffset) + 'px';
      marker.style.opacity = '1';
    } else {
      marker.style.top = String(outlineMarkerRestingTop) + 'px';
      marker.style.opacity = '0';
    }
  }

  var headingTops = null;

  function invalidateHeadingTops() {
    headingTops = null;
  }

  function resolveHeadingTops() {
    if (!headingTops) {
      headingTops = headings
        .map(function (heading) {
          return {
            hash: '#' + heading.id,
            top: getAbsoluteTop(heading)
          };
        })
        .filter(function (entry) {
          return !Number.isNaN(entry.top);
        })
        .sort(function (a, b) {
          return a.top - b.top;
        });
    }

    return headingTops;
  }

  window.addEventListener('resize', invalidateHeadingTops);
  // Layout shifts move the headings: late-loading images ('load' doesn't
  // bubble, hence capture) and toggled <details> blocks.
  document.addEventListener('load', invalidateHeadingTops, true);
  document.addEventListener('toggle', invalidateHeadingTops, true);

  function syncActiveHeading() {
    if (!hasOutline) {
      return;
    }

    var scrollY = window.scrollY || window.pageYOffset || 0;
    var innerHeight = window.innerHeight || 0;
    var offsetHeight = document.body ? document.body.offsetHeight : 0;
    var isBottom = Math.abs(scrollY + innerHeight - offsetHeight) < 1;

    var resolvedHeadings = resolveHeadingTops();

    if (!resolvedHeadings.length) {
      activateOutlineHash(null);
      return;
    }

    if (scrollY < 1) {
      activateOutlineHash(null);
      return;
    }

    if (isBottom) {
      activateOutlineHash(resolvedHeadings[resolvedHeadings.length - 1].hash);
      return;
    }

    var threshold = scrollY + getConfiguredScrollOffset() + 4;
    var activeHash = null;

    resolvedHeadings.forEach(function (entry) {
      if (entry.top > threshold) {
        return;
      }
      activeHash = entry.hash;
    });

    activateOutlineHash(activeHash);
  }

  syncActiveHeading();
  window.addEventListener('scroll', syncActiveHeading, { passive: true });

  function normalizePathname(path) {
    var value = String(path || '').trim();
    if (!value) {
      return '/';
    }
    value = value.replace(/[?#].*$/, '');
    if (value.length > 1) {
      value = value.replace(/\/+$/, '');
    }
    return value || '/';
  }

  var pendingDocFrameHash = null;

  function shouldTargetDocFrameLink(link) {
    if (!link) {
      return false;
    }

    var href = link.getAttribute('href');
    if (!href || href.charAt(0) === '#') {
      return false;
    }

    if (link.hasAttribute('target') || link.hasAttribute('download') || link.getAttribute('data-turbo') === 'false') {
      return false;
    }

    var url;
    try {
      url = new URL(href, window.location.href);
    } catch (error) {
      return false;
    }

    if (url.origin !== window.location.origin) {
      return false;
    }

    var currentPath = normalizePathname(window.location.pathname);
    var targetPath = normalizePathname(url.pathname);
    if (targetPath === '/' || (targetPath === currentPath && url.hash)) {
      return false;
    }

    var lastSegment = targetPath.split('/').pop();
    var hasExtension = lastSegment && lastSegment.indexOf('.') > -1;
    if (hasExtension && !/\.html?$/.test(lastSegment)) {
      return false;
    }

    return true;
  }

  function rememberDocFrameHash(event) {
    if (event.defaultPrevented || (typeof event.button === 'number' && event.button !== 0) ||
      event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
      return;
    }

    var link = event.currentTarget;
    if (!shouldTargetDocFrameLink(link)) {
      return;
    }

    var url;
    try {
      url = new URL(link.getAttribute('href'), window.location.href);
    } catch (error) {
      pendingDocFrameHash = null;
      return;
    }

    pendingDocFrameHash = url.hash || null;
  }

  function consumePendingDocFrameHash() {
    var hash = pendingDocFrameHash;
    pendingDocFrameHash = null;

    if (!hash || !getHashTarget(hash)) {
      return null;
    }

    return hash;
  }

  function restoreLocationHash(hash) {
    if (!hash || window.location.hash === hash) {
      return;
    }

    if (window.history && typeof window.history.replaceState === 'function') {
      window.history.replaceState(window.history.state, '', window.location.pathname + window.location.search + hash);
      return;
    }

    window.location.hash = hash;
  }

  function enhanceDocFrameLinks() {
    document.querySelectorAll('.vp-doc a[href], .VPDocFooter .pager-link').forEach(function (link) {
      if (!shouldTargetDocFrameLink(link)) {
        return;
      }
      link.setAttribute('data-turbo', 'true');
      link.setAttribute('data-turbo-frame', 'vp-content-frame');
      link.setAttribute('data-turbo-action', 'advance');
      if (!link.hasAttribute('data-vp-frame-hash-bound')) {
        link.setAttribute('data-vp-frame-hash-bound', 'true');
        link.addEventListener('click', rememberDocFrameHash);
      }
    });
  }

  function getSidebarItemScrollDistance(item) {
    if (!sidebar) {
      return 0;
    }

    var sidebarRect = sidebar.getBoundingClientRect();
    var itemRect = item.getBoundingClientRect();
    var itemTop = itemRect.top - sidebarRect.top + sidebar.scrollTop;

    return Math.abs(itemTop - sidebar.scrollTop);
  }

  function getActiveSidebarItemClosestToScrollPosition() {
    if (!sidebar) {
      return null;
    }

    var activeItems = Array.from(sidebar.querySelectorAll('.VPSidebarItem.is-link.is-active'));

    if (!activeItems.length) {
      return null;
    }

    return activeItems.reduce(function (closestItem, item) {
      if (!closestItem) {
        return item;
      }

      return getSidebarItemScrollDistance(item) < getSidebarItemScrollDistance(closestItem) ? item : closestItem;
    }, null);
  }

  function scrollActiveSidebarItemIntoView() {
    var activeItem = getActiveSidebarItemClosestToScrollPosition();

    if (activeItem) {
      activeItem.scrollIntoView({ block: 'nearest' });
    }
  }

  function syncPersistentNavState() {
    var frameState = document.getElementById('vp-page-state');
    if (!frameState) {
      return;
    }

    var currentPath = normalizePathname(frameState.getAttribute('data-url') || window.location.pathname);
    var currentCollection = frameState.getAttribute('data-collection') || '';
    var currentTitle = frameState.getAttribute('data-title') || '';

    if (currentTitle) {
      document.title = currentTitle;
    }

    document.querySelectorAll('[data-vp-sidebar-link]').forEach(function (link) {
      var item = link.closest('.VPSidebarItem.is-link');
      var active = normalizePathname(link.getAttribute('href')) === currentPath;
      if (item) {
        item.classList.toggle('is-active', active);
      }
    });

    document.querySelectorAll('.VPSidebarItem.collapsible').forEach(function (group) {
      var hasActiveLink = group.classList.contains('is-active') || !!group.querySelector('.VPSidebarItem.is-link.is-active');
      group.classList.toggle('has-active', hasActiveLink);
      if (hasActiveLink) {
        setSidebarSectionCollapsed(group, false);
      }
    });

    document.querySelectorAll('[data-vp-nav-link]').forEach(function (link) {
      var collections = (link.getAttribute('data-collections') || '').split('|').filter(Boolean);
      var active = collections.indexOf(currentCollection) >= 0 ||
        normalizePathname(link.getAttribute('href')) === currentPath;
      link.classList.toggle('active', active);
    });

    scrollActiveSidebarItemIntoView();
  }

  function refreshDocPageState() {
    copyMdBtn = document.querySelector('.copy-md-btn');
    toggle = document.querySelector('.copy-md-toggle');
    dropdown = document.querySelector('.copy-md-dropdown');
    dropdownCopy = dropdown ? dropdown.querySelector('[data-action="copy"]') : null;
    dropdownView = dropdown ? dropdown.querySelector('[data-action="view-markdown"]') : null;
    bindCopyPageControls();

    addCopyButtons();
    enhanceDocFrameLinks();

    content = document.querySelector('.vp-doc');
    if (!content) {
      return;
    }

    injectHeaderAnchors(content);

    headings = Array.from(content.querySelectorAll('h2[id], h3[id]'));
    asideOutline = document.querySelector('.VPDocAsideOutline');
    localNav = document.getElementById('vp-local-nav');
    localOutlineDropdown = document.getElementById('vp-local-outline-dropdown');
    localOutlineButton = document.getElementById('vp-local-outline-button');
    localOutlineItems = document.querySelector('#vp-local-outline-dropdown .items');
    localOutlineContainer = document.querySelector('#vp-local-outline-dropdown .outline .VPDocOutlineItem');
    localTopLink = document.getElementById('vp-local-top-link');
    returnToTopLabel = localTopLink && localTopLink.textContent ? localTopLink.textContent.trim() : 'Return to top';
    marker = document.getElementById('vp-outline-marker');
    localOutlineOpen = false;

    rebuildOutline();
    setLocalOutlineOpen(false, false);

    if (localOutlineButton && localOutlineItems && localOutlineItems.id) {
      localOutlineButton.setAttribute('aria-controls', localOutlineItems.id);
    }

    bindHashLinkHandlers();
    syncLocalOutlineViewportHeight();
    syncActiveHeading();
  }

  enhanceDocFrameLinks();
  syncPersistentNavState();

  if (window.Turbo) {
    document.addEventListener('turbo:frame-missing', function (event) {
      if (!event.target || event.target.id !== 'vp-content-frame') {
        return;
      }

      event.preventDefault();

      if (event.detail && typeof event.detail.visit === 'function' && event.detail.response) {
        event.detail.visit(event.detail.response);
        return;
      }

      if (event.detail && event.detail.response && event.detail.response.url) {
        window.location.href = event.detail.response.url;
      }
    });

    document.addEventListener('turbo:frame-load', function (event) {
      if (!event.target || event.target.id !== 'vp-content-frame') {
        return;
      }

      syncPersistentNavState();
      refreshDocPageState();
      loadMetricButtons(event.target);
      formatLastUpdatedTimes(event.target);

      var pendingHash = consumePendingDocFrameHash();
      if (pendingHash) {
        restoreLocationHash(pendingHash);
        scrollToHash(pendingHash, false);
      } else if (window.location.hash) {
        scrollToHash(window.location.hash, false);
      } else {
        window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
        activateOutlineHash(null);
      }

      syncActiveHeading();
      syncNavTop();

      if (window.innerWidth < 960 && sidebarOpen) {
        setSidebarOpen(false);
      }
    });
  }
})();
