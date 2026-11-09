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

  function scrollToSourceLine(line) {
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
  }

  function topLine() {
    let best = null;
    for (const element of positioned()) {
      if (element.getBoundingClientRect().bottom <= TOP_OFFSET) continue;
      if (best === null || best.contains(element)) best = element;
      else break;
    }
    return best ? lineOf(best) : 1;
  }

  let lastSettings = null;
  const darkTheme = window.matchMedia("(prefers-color-scheme: dark)");

  function luminance(hex) {
    const channel = (start) => {
      const value = parseInt(hex.slice(start, start + 2), 16) / 255;
      return value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4;
    };
    return 0.2126 * channel(1) + 0.7152 * channel(3) + 0.0722 * channel(5);
  }

  // A color picked in one theme can vanish in the other, so it applies only
  // when it stays readable on the current background.
  function isReadable(hex) {
    const background = luminance(darkTheme.matches ? "#0A0A0A" : "#F0EEE9");
    const color = luminance(hex);
    const contrast = (Math.max(color, background) + 0.05) / (Math.min(color, background) + 0.05);
    return contrast >= 2;
  }

  function applyPrimary() {
    const root = document.documentElement;
    const color = lastSettings && lastSettings.primaryColor;
    if (color && isReadable(color)) root.style.setProperty("--primary", color);
    else root.style.removeProperty("--primary");
  }
  darkTheme.addEventListener("change", applyPrimary);

  // Remote images never load, so they would only leave empty boxes.
  function removeRemoteImages() {
    article().querySelectorAll('img[src^="http:"], img[src^="https:"]').forEach((image) => {
      const link = image.parentElement.tagName === "A" ? image.parentElement : null;
      const block = (link || image).parentElement;
      (link || image).remove();
      if (block.tagName === "P" && !block.textContent.trim() && !block.children.length) block.remove();
    });
  }

  let scrollTimer = null;
  window.addEventListener("scroll", () => {
    clearTimeout(scrollTimer);
    scrollTimer = setTimeout(() => window.webkit.messageHandlers.zreadScroll.postMessage(topLine()), 300);
  });

  return {
    applySettings(settings) {
      const root = document.documentElement;
      root.style.setProperty("--reader-font-size", `${settings.fontSize}px`);
      root.style.setProperty("--reader-line-height", String(settings.lineHeight));
      root.style.setProperty("--reader-tracking", `${settings.letterSpacing}em`);
      root.dataset.fontStyle = settings.fontStyle;
      lastSettings = settings;
      applyPrimary();
    },

    setContent(html, shouldHighlight) {
      article().innerHTML = html;
      removeRemoteImages();
      addHeadingIds();
      window.scrollTo(0, 0);
      if (shouldHighlight) highlight();
    },

    topVisibleLine() {
      return topLine();
    },

    scrollToLine(line) {
      scrollToSourceLine(line);
      // Fonts and images change the layout after they load, so land again.
      const images = [...article().querySelectorAll("img")].map((image) => image.decode().catch(() => {}));
      Promise.all([document.fonts.ready, ...images]).then(() => scrollToSourceLine(line));
    },

    scrollToAnchor(id) {
      const element = document.getElementById(id);
      if (element) element.scrollIntoView();
    },
  };
})();
