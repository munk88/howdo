// 全局客户端交互：主题切换 / 搜索 / 阅读进度 / 回到顶部
(function () {
  // 主题切换（图标明暗互换）
  var btn = document.getElementById('theme-toggle');
  var sun = document.getElementById('icon-sun');
  var moon = document.getElementById('icon-moon');
  function syncIcons() {
    var dark = document.documentElement.dataset.theme === 'dark';
    if (sun) sun.style.display = dark ? 'block' : 'none';
    if (moon) moon.style.display = dark ? 'none' : 'block';
  }
  syncIcons();
  if (btn) {
    btn.addEventListener('click', function () {
      var next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
      document.documentElement.dataset.theme = next;
      try { localStorage.setItem('blog-theme', next); } catch (e) {}
      syncIcons();
    });
  }

  // 全局搜索遮罩
  var overlay = document.getElementById('search-overlay');
  var openBtn = document.getElementById('search-open');
  var closeBtn = document.getElementById('search-close');
  var input = document.getElementById('search-input');
  var results = document.getElementById('search-results');
  var indexEl = document.getElementById('search-index');
  var index = [];
  try { if (indexEl) index = JSON.parse(indexEl.textContent); } catch (e) {}

  function renderSearch(q) {
    if (!results) return;
    q = (q || '').trim().toLowerCase();
    var list = index.filter(function (it) {
      if (!q) return true;
      return (it.title + ' ' + it.desc + ' ' + it.category + ' ' + (it.tags || []).join(' '))
        .toLowerCase()
        .includes(q);
    });
    if (!q) {
      results.innerHTML = '<li class="hint">输入关键词，搜索标题、栏目或标签</li>';
      return;
    }
    if (!list.length) {
      results.innerHTML = '<li class="none">没有找到相关文章</li>';
      return;
    }
    results.innerHTML = list
      .slice(0, 8)
      .map(function (it) {
        return (
          '<li><a href="/posts/' + it.slug + '/">' +
          '<span class="t">' + it.title + '</span>' +
          '<span class="m">' + it.category + ' · ' + it.date + '</span></a></li>'
        );
      })
      .join('');
  }
  function openSearch() {
    if (!overlay) return;
    overlay.hidden = false;
    document.body.classList.add('search-open');
    if (input) { input.value = ''; renderSearch(''); setTimeout(function () { input.focus(); }, 10); }
  }
  function closeSearch() {
    if (!overlay) return;
    overlay.hidden = true;
    document.body.classList.remove('search-open');
  }
  if (openBtn) openBtn.addEventListener('click', function (e) { e.stopPropagation(); openSearch(); });
  if (closeBtn) closeBtn.addEventListener('click', closeSearch);
  if (input) {
    input.addEventListener('input', function () { renderSearch(input.value); });
    input.addEventListener('keydown', function (e) {
      if (e.key === 'Enter') {
        var first = results && results.querySelector('a');
        if (first) { location.href = first.getAttribute('href'); }
      }
    });
  }
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && overlay && !overlay.hidden) closeSearch();
  });
  if (overlay) {
    overlay.addEventListener('click', function (e) {
      if (e.target === overlay) closeSearch();
    });
  }

  // 阅读进度：仅文章页显示
  var bar = document.getElementById('read-progress');
  var isArticle = !!document.querySelector('.article-view');
  if (bar && isArticle) bar.classList.add('show');

  // 回到顶部
  var topBtn = document.getElementById('to-top');
  function onScroll() {
    if (bar && isArticle) {
      var max = document.documentElement.scrollHeight - window.innerHeight;
      var pct = max > 0 ? (window.scrollY / max) * 100 : 0;
      var fill = bar.firstElementChild;
      if (fill) fill.style.width = pct + '%';
    }
    if (topBtn) topBtn.classList.toggle('show', window.scrollY > 600);
  }
  window.addEventListener('scroll', onScroll, { passive: true });
  if (topBtn) {
    topBtn.addEventListener('click', function () {
      var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      window.scrollTo({ top: 0, behavior: reduce ? 'auto' : 'smooth' });
    });
  }
})();
