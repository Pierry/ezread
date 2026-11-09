"use strict";

window.zread = (() => {
  const TOP_OFFSET = 56;
  let highlightLoading = null;

  const article = () => document.getElementById("article");
  const lineOf = (element) => parseInt(element.getAttribute("data-sourcepos"), 10);
  const positioned = () => article().querySelectorAll("[data-sourcepos]");

  function addHeadingIds() {
    const seen = new Map();
    article().querySelectorAll("h1, h2, h3, h4, h5, h6").forEach((heading) => {
      const base = heading.textContent
        .trim()
        .toLowerCase()
        .replace(/[^\p{L}\p{N}\s_-]/gu, "")
        .replace(/\s/g, "-");
      const count = seen.get(base) || 0;
      seen.set(base, count + 1);
      heading.id = count === 0 ? base : `${base}-${count}`;
    });
  }

  function loadHighlight() {
    if (window.hljs) return Promise.resolve();
    if (!highlightLoading) {
      highlightLoading = new Promise((resolve, reject) => {
        const script = document.createElement("script");
        script.src = "zread://app/vendor/highlight.min.js";
        script.onload = resolve;
        script.onerror = reject;
        document.head.appendChild(script);
      });
    }
    return highlightLoading;
  }

  function highlight() {
    loadHighlight()
      .then(() => {
        window.hljs.configure({ ignoreUnescapedHTML: true });
        article()
          .querySelectorAll('pre code[class*="language-"]')
          .forEach((block) => window.hljs.highlightElement(block));
      })
      .catch(() => {});
  }

  return {
    applySettings(settings) {
      const root = document.documentElement;
      root.style.setProperty("--reader-font-size", `${settings.fontSize}px`);
      root.style.setProperty("--reader-line-height", String(settings.lineHeight));
      root.style.setProperty("--reader-tracking", `${settings.letterSpacing}em`);
      root.dataset.fontStyle = settings.fontStyle;
      if (settings.primaryColor) root.style.setProperty("--primary", settings.primaryColor);
      else root.style.removeProperty("--primary");
    },

    setContent(html, shouldHighlight) {
      article().innerHTML = html;
      addHeadingIds();
      window.scrollTo(0, 0);
      if (shouldHighlight) highlight();
    },

    topVisibleLine() {
      let best = null;
      for (const element of positioned()) {
        if (element.getBoundingClientRect().bottom <= TOP_OFFSET) continue;
        if (best === null || best.contains(element)) best = element;
        else break;
      }
      return best ? lineOf(best) : 1;
    },

    scrollToLine(line) {
      let target = null;
      for (const element of positioned()) {
        if (lineOf(element) <= line) target = element;
        else break;
      }
      if (!target) {
        window.scrollTo(0, 0);
        return;
      }
      const top = target.getBoundingClientRect().top + window.scrollY - TOP_OFFSET;
      window.scrollTo(0, Math.max(0, top));
    },

    scrollToAnchor(id) {
      const element = document.getElementById(id);
      if (element) element.scrollIntoView();
    },
  };
})();
