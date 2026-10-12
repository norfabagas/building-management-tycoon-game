"""Deduplicate byte-identical embedded media without altering the artwork."""
import hashlib
import posixpath
import sys
import xml.etree.ElementTree as ET
import zipfile

source, target = sys.argv[1:]
ns = "http://schemas.openxmlformats.org/package/2006/relationships"
ET.register_namespace("", ns)
with zipfile.ZipFile(source) as incoming:
    payloads = {name: incoming.read(name) for name in incoming.namelist()}
    hashes, redirects = {}, {}
    for name, data in payloads.items():
        if name.startswith("ppt/media/"):
            digest = hashlib.sha256(data).digest()
            if digest in hashes:
                redirects[name] = hashes[digest]
            else:
                hashes[digest] = name
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as outgoing:
        for name, data in payloads.items():
            if name in redirects:
                continue
            if name.endswith(".rels"):
                owner = name.split("/_rels/")[0] if "/_rels/" in name else ""
                xml = ET.fromstring(data)
                changed = False
                for rel in xml:
                    if rel.get("TargetMode") == "External":
                        continue
                    current = rel.get("Target", "")
                    resolved = posixpath.normpath(posixpath.join(owner, current)).lstrip("/")
                    if resolved in redirects:
                        rel.set("Target", "/" + redirects[resolved] if current.startswith("/") else posixpath.relpath(redirects[resolved], owner or "."))
                        changed = True
                if changed:
                    data = ET.tostring(xml, encoding="utf-8", xml_declaration=True)
            outgoing.writestr(name, data)
print(f"Reused {len(redirects)} duplicate media parts; kept {len(hashes)} unique media parts")
