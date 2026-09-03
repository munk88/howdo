// 全局客户端交互：主题切换 / 阅读进度 / 回到顶部
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
