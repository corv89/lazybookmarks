/** Create a favicon <img> element for a bookmark URL. */
export function createFavicon(url) {
  const img = document.createElement('img');
  img.className = 'favicon';
  img.alt = '';
  img.width = 16;
  img.height = 16;
  img.loading = 'lazy';
  try {
    const domain = new URL(url).hostname;
    img.src = `https://www.google.com/s2/favicons?domain=${encodeURIComponent(domain)}&sz=16`;
  } catch {
    img.src = '';
  }
  img.onerror = function () {
    this.style.visibility = 'hidden';
  };
  return img;
}
