#!/usr/bin/env python3
"""Insert a new Sparkle appcast item for the current release."""

import os
import sys
from datetime import datetime, timezone

version = os.environ["VERSION"]
build = os.environ["GITHUB_RUN_NUMBER"]
repo = os.environ["GITHUB_REPOSITORY"]
tag = os.environ["TAG"]
app_name = os.environ["APP_NAME"]
signature = os.environ["SPARKLE_SIGNATURE"]
dmg_size = os.environ["DMG_SIZE"]

dmg_url = f"https://github.com/{repo}/releases/download/{tag}/{app_name}.dmg"
pub_date = datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S %z")

new_item = f"""    <item>
      <title>Version {version}</title>
      <pubDate>{pub_date}</pubDate>
      <sparkle:version>{build}</sparkle:version>
      <sparkle:shortVersionString>{version}</sparkle:shortVersionString>
      <enclosure url="{dmg_url}"
                 sparkle:edSignature="{signature}"
                 length="{dmg_size}"
                 type="application/octet-stream"/>
    </item>"""

with open("appcast.xml", "r") as f:
    content = f.read()

if "</channel>" not in content:
    print("Error: </channel> not found in appcast.xml", file=sys.stderr)
    sys.exit(1)

content = content.replace("</channel>", new_item + "\n  </channel>")

with open("appcast.xml", "w") as f:
    f.write(content)

print(f"Updated appcast.xml with version {version}")
