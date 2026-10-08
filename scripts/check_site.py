#!/usr/bin/env python3
"""Check rendered local links, anchors, and substantive figure alt text."""

from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1] / "_site"


class Page(HTMLParser):
    def __init__(self, html):
        super().__init__()
        self.ids, self.links, self.missing_alt = set(), [], []
        self.feed(html)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "id" in attrs:
            self.ids.add(attrs["id"])
        for attribute in ("href", "src"):
            if attrs.get(attribute):
                self.links.append(attrs[attribute])
        if tag == "img" and "figures/" in attrs.get("src", "") and not attrs.get("alt", "").strip():
            self.missing_alt.append(attrs["src"])


def main():
    paths = sorted(ROOT.rglob("*.html"))
    if not paths:
        raise SystemExit("No rendered HTML; run quarto render first.")
    pages = {p.resolve(): Page(p.read_text(encoding="utf-8")) for p in paths}
    errors = []
    for path, page in pages.items():
        for source in page.missing_alt:
            errors.append(f"{path.relative_to(ROOT)}: missing figure alt text: {source}")
        for link in page.links:
            url = urlsplit(link)
            if url.scheme or url.netloc:
                continue
            target = (ROOT / unquote(url.path).lstrip("/") if url.path.startswith("/")
                      else path.parent / unquote(url.path) if url.path else path).resolve()
            if target.is_dir():
                target /= "index.html"
            if not target.exists():
                errors.append(f"{path.relative_to(ROOT)}: missing local target: {link}")
            elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
                errors.append(f"{path.relative_to(ROOT)}: missing anchor: {link}")
    if errors:
        raise SystemExit("\n".join(errors))
    print(f"Checked {len(pages)} HTML pages: local links, anchors, and figure alt text passed.")


if __name__ == "__main__":
    main()
