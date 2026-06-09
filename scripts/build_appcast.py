#!/usr/bin/env python3
"""Build and merge the Sparkle appcast for an Offdesk release.

`generate_appcast` prunes entries whose archives are no longer present, so it
can't maintain a cumulative feed in CI (where only the new DMG is on disk).
Instead we hand-build the new `<item>` (the DMG is already EdDSA-signed by
`sign_update`) and merge it with the previously published appcast, which we
download from the prior GitHub release.

Items are de-duplicated by `sparkle:version` (the CFBundleVersion build number)
and sorted newest-first. Existing items are copied through verbatim, so their
signatures are never disturbed.
"""
import argparse
import html
import re
import sys

NEW_ITEM_TEMPLATE = """    <item>
      <title>{short_version}</title>
      <pubDate>{pub_date}</pubDate>
      <sparkle:version>{version}</sparkle:version>
      <sparkle:shortVersionString>{short_version}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>{min_system}</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>{notes_link}</sparkle:releaseNotesLink>
      <enclosure url="{url}" {enclosure_attrs} type="application/octet-stream"/>
    </item>"""

CHANNEL_TEMPLATE = """<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>{title}</title>
    <link>{link}</link>
    <description>Most recent updates to Offdesk.</description>
    <language>en</language>
{items}
  </channel>
</rss>
"""

ITEM_RE = re.compile(r"<item>.*?</item>", re.DOTALL)
VERSION_RE = re.compile(r"<sparkle:version>\s*(\d+)\s*</sparkle:version>")
VERSION_ATTR_RE = re.compile(r'sparkle:version="(\d+)"')


def item_version(block: str) -> int:
    """Return the build number for an <item> block, or -1 if absent."""
    m = VERSION_RE.search(block) or VERSION_ATTR_RE.search(block)
    return int(m.group(1)) if m else -1


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--version", required=True, help="CFBundleVersion (build number)")
    p.add_argument("--short-version", required=True, help="CFBundleShortVersionString")
    p.add_argument("--url", required=True, help="Download URL for the DMG")
    p.add_argument("--enclosure-attrs", required=True,
                   help='Output of sign_update, e.g. sparkle:edSignature="…" length="…"')
    p.add_argument("--min-system", required=True, help="LSMinimumSystemVersion")
    p.add_argument("--pub-date", required=True, help="RFC 822 publication date")
    p.add_argument("--notes-link", required=True, help="Release notes URL")
    p.add_argument("--previous", default="", help="Path to the previous appcast (optional)")
    p.add_argument("--output", required=True)
    p.add_argument("--title", default="Offdesk")
    p.add_argument("--link", default="https://github.com/carlrosell/offdesk")
    args = p.parse_args()

    new_version = int(args.version)
    new_item = NEW_ITEM_TEMPLATE.format(
        short_version=html.escape(args.short_version),
        pub_date=html.escape(args.pub_date),
        version=new_version,
        min_system=html.escape(args.min_system),
        notes_link=html.escape(args.notes_link, quote=True),
        url=html.escape(args.url, quote=True),
        enclosure_attrs=args.enclosure_attrs.strip(),
    )

    # New item always wins over any same-version entry in the old feed.
    items: dict[int, str] = {new_version: new_item}

    prev_text = ""
    if args.previous:
        try:
            with open(args.previous, encoding="utf-8") as f:
                prev_text = f.read()
        except OSError:
            prev_text = ""

    for block in ITEM_RE.findall(prev_text):
        v = item_version(block)
        if v < 0 or v in items:
            continue
        items[v] = "    " + block  # normalise indentation under <channel>

    ordered = [items[v] for v in sorted(items, reverse=True)]
    out = CHANNEL_TEMPLATE.format(
        title=html.escape(args.title),
        link=html.escape(args.link, quote=True),
        items="\n".join(ordered),
    )
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(out)
    print(f"Wrote {args.output} with {len(ordered)} item(s): "
          f"versions {sorted(items, reverse=True)}", file=sys.stderr)


if __name__ == "__main__":
    main()
