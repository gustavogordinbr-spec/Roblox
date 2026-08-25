#!/usr/bin/env python3
"""Extract Luau source and searchable instance metadata from binary Roblox places."""

from __future__ import annotations

import argparse
import json
import re
from collections import defaultdict
from pathlib import Path

import rbxl_tool as binary


def load_place(path: Path) -> dict:
    _, _, _, chunks = binary.parse_chunks(path)
    classes = {}
    instances = {}
    parents = {}
    source = {}
    property_types = defaultdict(dict)
    simple_strings = defaultdict(dict)

    for chunk in chunks:
        if chunk.kind == b"INST":
            reader = binary.Reader(chunk.payload())
            class_id = reader.u32()
            class_name = reader.string()
            reader.u8()
            count = reader.u32()
            refs = binary.decode_referents(reader.data[reader.offset :], count)
            classes[class_id] = {"name": class_name, "refs": refs}
            for ref in refs:
                instances[ref] = {"class": class_name, "name": class_name}
        elif chunk.kind == b"PROP":
            reader = binary.Reader(chunk.payload())
            class_id = reader.u32()
            property_name = reader.string()
            property_type = reader.u8()
            class_info = classes.get(class_id)
            if not class_info:
                continue
            property_types[class_info["name"]][property_name] = property_type
            if property_type == 1 and property_name in {"Name", "Source", "AnimationId", "SoundId", "Texture"}:
                for ref in class_info["refs"]:
                    value = reader.string()
                    if property_name == "Name":
                        instances[ref]["name"] = value
                    elif property_name == "Source":
                        source[ref] = value
                    else:
                        simple_strings[ref][property_name] = value
        elif chunk.kind == b"PRNT":
            reader = binary.Reader(chunk.payload())
            reader.u8()
            count = reader.u32()
            refs = binary.decode_referents(reader.data[reader.offset :], count)
            reader.offset += 4 * count
            parent_refs = binary.decode_referents(reader.data[reader.offset :], count)
            parents = dict(zip(refs, parent_refs))

    def path_for(ref: int) -> str:
        chain = []
        seen = set()
        current = ref
        while current != -1 and current in instances and current not in seen:
            seen.add(current)
            chain.append(instances[current]["name"])
            current = parents.get(current, -1)
        return "/".join(reversed(chain))

    scripts = []
    for ref, text in source.items():
        info = instances[ref]
        scripts.append(
            {
                "referent": ref,
                "class": info["class"],
                "name": info["name"],
                "path": path_for(ref),
                "bytes": len(text.encode("utf-8")),
                "lines": text.count("\n") + 1,
                "source": text,
            }
        )
    scripts.sort(key=lambda item: item["path"])

    assets = []
    for ref, properties in simple_strings.items():
        if properties:
            assets.append(
                {
                    "referent": ref,
                    "class": instances[ref]["class"],
                    "name": instances[ref]["name"],
                    "path": path_for(ref),
                    "properties": properties,
                }
            )
    return {
        "scripts": scripts,
        "assets": assets,
        "property_types": dict(property_types),
        "instances": instances,
        "parents": parents,
    }


def export_scripts(place: dict, destination: Path, pattern: str | None) -> dict:
    destination.mkdir(parents=True, exist_ok=True)
    regex = re.compile(pattern, re.IGNORECASE) if pattern else None
    exported = []
    for index, item in enumerate(place["scripts"]):
        if regex and not regex.search(item["path"]):
            continue
        safe = re.sub(r"[^A-Za-z0-9_.-]+", "_", item["path"])
        target = destination / f"{index:03d}_{safe}.luau"
        target.write_text(item["source"], encoding="utf-8")
        exported.append({key: value for key, value in item.items() if key != "source"} | {"file": str(target)})
    return {"count": len(exported), "scripts": exported}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("place", type=Path)
    parser.add_argument("--destination", type=Path)
    parser.add_argument("--pattern")
    parser.add_argument("--assets")
    parser.add_argument("--property-class")
    args = parser.parse_args()
    place = load_place(args.place)
    if args.destination:
        result = export_scripts(place, args.destination, args.pattern)
    elif args.assets:
        regex = re.compile(args.assets, re.IGNORECASE)
        result = {"assets": [item for item in place["assets"] if regex.search(item["path"])][:100]}
    elif args.property_class:
        result = {"class": args.property_class, "properties": place["property_types"].get(args.property_class, {})}
    else:
        result = {
            "count": len(place["scripts"]),
            "scripts": [{key: value for key, value in item.items() if key != "source"} for item in place["scripts"]],
        }
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
