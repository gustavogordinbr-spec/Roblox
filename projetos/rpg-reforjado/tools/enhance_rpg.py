#!/usr/bin/env python3
"""Repair an existing Roblox binary place while preserving its complete scene graph."""

from __future__ import annotations

import argparse
import json
import struct
from collections import Counter, defaultdict
from pathlib import Path

import rbxl_diagnostics as diagnostics
import rbxl_tool as binary


ROOT = Path(__file__).resolve().parent
SOURCES = ROOT / "improved_rpg"

REPLACEMENTS = {
    "ReplicatedStorage/Modules/Classes": "OriginalFixes/Classes.luau",
    "ReplicatedStorage/Modules/Racas": "OriginalFixes/Racas.luau",
    "ReplicatedStorage/Modules/Stats": "OriginalFixes/Stats.luau",
    "ReplicatedStorage/Modules/XPConfig": "OriginalFixes/XPConfig.luau",
    "ReplicatedStorage/Modules/XPService": "OriginalFixes/XPService.luau",
    "ReplicatedStorage/Modules/QuestService": "OriginalFixes/QuestService.luau",
    "ServerScriptService/DataStore": "OriginalFixes/DataStore.server.luau",
    "ServerScriptService/CombatHandler": "OriginalFixes/CombatHandler.server.luau",
    "ServerScriptService/Combo": "OriginalFixes/Combo.server.luau",
    "ServerScriptService/GameManager": "OriginalFixes/GameManager.server.luau",
    "ServerScriptService/GoblinHandler": "OriginalFixes/GoblinHandler.server.luau",
    "ServerScriptService/QuestHandler": "OriginalFixes/QuestHandler.server.luau",
    "ServerScriptService/RespawnServer": "OriginalFixes/RespawnServer.server.luau",
    "ServerScriptService/Systems/PlayerStatsController": "OriginalFixes/PlayerStatsController.server.luau",
    "ServerScriptService/Systems/EnergyReload": "OriginalFixes/EnergyReload.server.luau",
    "StarterGui/HUD/LocalScript": "OriginalFixes/HUD.client.luau",
    "StarterGui/Quest/QuestFrame/Hud": "OriginalFixes/QuestHUD.client.luau",
    "StarterPack/Combat/Main": "OriginalFixes/CombatTool.client.luau",
    "StarterPlayer/StarterPlayerScripts/Sprint": "OriginalFixes/Sprint.client.luau",
    "StarterPlayer/StarterCharacterScripts/Replication": "OriginalFixes/Replication.client.luau",
    "StarterPack/Sword/SwordScript": "OriginalFixes/SwordScript.server.luau",
    "Workspace/Bandit/Follow": "OriginalFixes/BanditAI.server.luau",
}

DONOR_ANIMATIONS = {
    "QuirkFist1": "ServerStorage/GameAssets/Animations/Fists/Fist1",
    "QuirkFist2": "ServerStorage/GameAssets/Animations/Fists/Fist2",
    "QuirkFist3": "ServerStorage/GameAssets/Animations/Fists/Fist3",
    "QuirkFist4": "ServerStorage/GameAssets/Animations/Fists/Fist4",
    "QuirkFist5": "ServerStorage/GameAssets/Animations/Fists/Fist5",
    "QuirkHeavy": "ServerStorage/GameAssets/Animations/Fists/FistHeavy",
    "QuirkAirStrike": "ServerStorage/GameAssets/Animations/Fists/AirFist",
    "QuirkDownSlam": "ServerStorage/GameAssets/Animations/Fists/DownSlam",
    "QuirkCombatIdle": "ServerStorage/GameAssets/Animations/Fists/Idle",
    "QuirkSprint": "ServerStorage/GameAssets/Animations/Sprint",
    "QuirkSword1": "ServerStorage/GameAssets/Animations/Noble-Sword/Fist1",
    "QuirkSword2": "ServerStorage/GameAssets/Animations/Noble-Sword/Fist2",
    "QuirkSword3": "ServerStorage/GameAssets/Animations/Noble-Sword/Fist3",
    "QuirkSword4": "ServerStorage/GameAssets/Animations/Noble-Sword/Fist4",
    "QuirkSword5": "ServerStorage/GameAssets/Animations/Noble-Sword/Fist5",
    "QuirkSwordHeavy": "ServerStorage/GameAssets/Animations/Noble-Sword/FistHeavy",
    "QuirkSwordEquip": "ServerStorage/GameAssets/Animations/Noble-Sword/Equip",
    "QuirkSwordIdle": "ServerStorage/GameAssets/Animations/Noble-Sword/Idle",
    "QuirkSwordBlock": "ServerStorage/GameAssets/Animations/Noble-Sword/Block",
    "QuirkSwordParry": "ServerStorage/GameAssets/Animations/Noble-Sword/parrytick",
    "QuirkBlockReact": "ServerStorage/GameAssets/Animations/Noble-Sword/FistBlockReact",
    "QuirkBow": "ServerStorage/GameAssets/Animations/Emotes/Bow",
    "QuirkVictory": "ServerStorage/GameAssets/Animations/Emotes/VictoryPose",
    "QuirkVictory2": "ServerStorage/GameAssets/Animations/Emotes/VictoryPose2",
}


def path_for(place: dict, referent: int) -> str:
    names, seen = [], set()
    current = referent
    while current != -1 and current in place["instances"] and current not in seen:
        seen.add(current)
        names.append(place["instances"][current]["name"])
        current = place["parents"].get(current, -1)
    return "/".join(reversed(names))


def class_groups(chunks: list[binary.Chunk]) -> dict[int, dict]:
    groups = {}
    for chunk in chunks:
        if chunk.kind != b"INST":
            continue
        reader = binary.Reader(chunk.payload())
        identifier = reader.u32()
        name = reader.string()
        service = reader.u8()
        count = reader.u32()
        groups[identifier] = {
            "class": name,
            "service": service,
            "refs": binary.decode_referents(reader.data[reader.offset :], count),
        }
    return groups


def replace_original_sources(chunks: list[binary.Chunk], groups: dict, fixes: dict[int, str]) -> int:
    count = 0
    for index, chunk in enumerate(chunks):
        if chunk.kind != b"PROP":
            continue
        reader = binary.Reader(chunk.payload())
        identifier = reader.u32()
        name = reader.string()
        kind = reader.u8()
        group = groups.get(identifier)
        if name != "Source" or kind != 1 or not group:
            continue
        values = [reader.string() for _ in group["refs"]]
        changed = False
        for offset, referent in enumerate(group["refs"]):
            if referent in fixes:
                values[offset] = fixes[referent]
                count += 1
                changed = True
        if changed:
            payload = struct.pack("<I", identifier) + binary.encode_string("Source") + b"\x01"
            payload += b"".join(binary.encode_string(value) for value in values)
            chunks[index] = binary.compressed_chunk(b"PROP", payload)
    return count


def enhance(source_path: Path, donor_path: Path, output_path: Path) -> dict:
    version, original_class_count, original_instance_count, chunks = binary.parse_chunks(source_path)
    original = diagnostics.load_place(source_path)
    donor = diagnostics.load_place(donor_path)
    groups = class_groups(chunks)
    paths = {path_for(original, ref): ref for ref in original["instances"]}
    scripts = {item["path"]: item for item in original["scripts"]}
    assets = {item["path"]: item for item in donor["assets"]}

    missing = sorted(path for path in REPLACEMENTS if path not in scripts)
    if missing:
        raise ValueError(f"Original scripts were not found: {missing}")
    fixes = {}
    for item in original["scripts"]:
        filename = REPLACEMENTS.get(item["path"])
        if filename:
            fixes[item["referent"]] = (SOURCES / filename).read_text(encoding="utf-8")
    fixed_count = replace_original_sources(chunks, groups, fixes)
    if fixed_count != len(fixes):
        raise ValueError(f"Only replaced {fixed_count} of {len(fixes)} scripts")

    required_paths = {
        "ReplicatedStorage",
        "ReplicatedStorage/Remotes",
        "ServerScriptService",
        "ServerStorage",
        "StarterPlayer/StarterPlayerScripts",
    }
    if not required_paths.issubset(paths):
        raise ValueError(f"Required hierarchy missing: {sorted(required_paths - paths.keys())}")

    next_referent = max(original["instances"]) + 1
    additions = []

    def add(class_name: str, name: str, parent: int, file: str | None = None, animation: str | None = None) -> int:
        nonlocal next_referent
        referent = next_referent
        next_referent += 1
        source = (SOURCES / file).read_text(encoding="utf-8") if file else None
        additions.append({"class": class_name, "name": name, "parent": parent, "ref": referent, "source": source, "file": file, "animation": animation})
        return referent

    root = add("Folder", "RPGEnhancements", paths["ReplicatedStorage"])
    animation_folder = add("Folder", "Animations", root)
    add("ModuleScript", "EnhancementConfig", root, "Shared/EnhancementConfig.luau")
    add("ModuleScript", "QuirkMaid", root, "Shared/QuirkMaid.luau")
    imported = []
    for name, donor_item in DONOR_ANIMATIONS.items():
        item = assets.get(donor_item)
        animation_id = item and item["properties"].get("AnimationId")
        if not animation_id or not animation_id.startswith("rbxassetid://"):
            raise ValueError(f"Required Quirkbound animation missing: {donor_item}")
        add("Animation", name, animation_folder, animation=animation_id)
        imported.append({"name": name, "source": donor_item, "animation_id": animation_id})

    remotes = paths["ReplicatedStorage/Remotes"]
    for name in ("LevelUp", "RPGNotification", "RPGAction"):
        add("RemoteEvent", name, remotes)
    add("RemoteFunction", "RPGRequestState", remotes)

    storage = paths["ServerStorage"]
    for name in ("LevelUpNotifier", "BossMorto"):
        if f"ServerStorage/{name}" not in paths:
            add("BindableEvent", name, storage)

    server = add("Folder", "RPGEnhancements", paths["ServerScriptService"])
    for name, file in (
        ("SprintController", "Server/SprintController.server.luau"),
        ("CombatActions", "Server/CombatActions.server.luau"),
        ("NPCEnhancer", "Server/NPCEnhancer.server.luau"),
        ("RPGState", "Server/RPGState.server.luau"),
    ):
        add("Script", name, server, file)

    starter = paths["StarterPlayer/StarterPlayerScripts"]
    add("LocalScript", "RPGEnhancedInterface", starter, "Client/RPGInterface.client.luau")
    add("LocalScript", "QuirkMovement", starter, "Client/QuirkMovement.client.luau")

    grouped = defaultdict(list)
    for addition in additions:
        grouped[addition["class"]].append(addition)

    inserted, new_groups = [], []
    next_class = original_class_count
    for class_name in ("Folder", "ModuleScript", "Animation", "RemoteEvent", "RemoteFunction", "BindableEvent", "Script", "LocalScript"):
        items = grouped.get(class_name, [])
        if not items:
            continue
        class_id = next_class
        next_class += 1
        refs = [item["ref"] for item in items]
        payload = struct.pack("<I", class_id) + binary.encode_string(class_name) + b"\x00" + struct.pack("<I", len(items)) + binary.encode_referents(refs)
        inserted.append(binary.compressed_chunk(b"INST", payload))

        def append_strings(prop: str, values: list[str]) -> None:
            body = struct.pack("<I", class_id) + binary.encode_string(prop) + b"\x01"
            body += b"".join(binary.encode_string(value) for value in values)
            inserted.append(binary.compressed_chunk(b"PROP", body))

        append_strings("Name", [item["name"] for item in items])
        if class_name in {"Script", "LocalScript", "ModuleScript"}:
            append_strings("Source", [item["source"] or "" for item in items])
        if class_name == "Animation":
            append_strings("AnimationId", [item["animation"] or "" for item in items])
        new_groups.append({"id": class_id, "class": class_name, "count": len(items)})

    prnt_index = next((index for index, chunk in enumerate(chunks) if chunk.kind == b"PRNT"), -1)
    if prnt_index < 0:
        raise ValueError("PRNT graph was not found")
    reader = binary.Reader(chunks[prnt_index].payload())
    parent_version = reader.u8()
    count = reader.u32()
    children = binary.decode_referents(reader.data[reader.offset :], count)
    reader.offset += count * 4
    parents = binary.decode_referents(reader.data[reader.offset :], count)
    children.extend(item["ref"] for item in additions)
    parents.extend(item["parent"] for item in additions)
    graph = bytes([parent_version]) + struct.pack("<I", len(children)) + binary.encode_referents(children) + binary.encode_referents(parents)
    chunks[prnt_index] = binary.compressed_chunk(b"PRNT", graph)
    chunks[prnt_index:prnt_index] = inserted

    header = bytearray(source_path.read_bytes()[:32])
    struct.pack_into("<HII", header, len(binary.MAGIC), version, next_class, original_instance_count + len(additions))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("wb") as target:
        target.write(header)
        for chunk in chunks:
            target.write(chunk.encoded())

    return {
        "source": str(source_path),
        "output": str(output_path),
        "original_instances": original_instance_count,
        "output_instances": original_instance_count + len(additions),
        "fixed_existing_scripts": fixed_count,
        "fixed_paths": sorted(REPLACEMENTS),
        "added_instances": len(additions),
        "added_by_class": dict(Counter(item["class"] for item in additions)),
        "imported_quirkbound_animations": imported,
        "classes": new_groups,
        "output_bytes": output_path.stat().st_size,
    }


def validate(original_path: Path, modified_path: Path) -> dict:
    _, original_classes, original_instances, original_chunks = binary.parse_chunks(original_path)
    _, modified_classes, modified_instances, modified_chunks = binary.parse_chunks(modified_path)
    before = diagnostics.load_place(original_path)
    after = diagnostics.load_place(modified_path)
    if len(after["instances"]) != modified_instances or len(after["parents"]) != modified_instances:
        raise ValueError("Output graph does not match instance header")
    if len(class_groups(modified_chunks)) != modified_classes:
        raise ValueError("Output class groups do not match class header")
    for ref, instance in before["instances"].items():
        if after["instances"].get(ref) != instance or after["parents"].get(ref) != before["parents"].get(ref):
            raise ValueError(f"Original instance or parent changed: {ref}")

    original_non_source = []
    for chunk in original_chunks:
        if chunk.kind == b"PRNT":
            continue
        if chunk.kind == b"PROP":
            reader = binary.Reader(chunk.payload())
            reader.u32()
            if reader.string() == "Source":
                continue
        original_non_source.append(chunk.encoded())
    output_non_source = []
    for chunk in modified_chunks:
        if chunk.kind == b"PRNT":
            continue
        if chunk.kind in {b"INST", b"PROP"}:
            reader = binary.Reader(chunk.payload())
            identifier = reader.u32()
            if identifier >= original_classes:
                continue
            if chunk.kind == b"PROP" and reader.string() == "Source":
                continue
        output_non_source.append(chunk.encoded())
    if original_non_source != output_non_source:
        raise ValueError("A non-source original chunk changed")

    old_scripts = {item["referent"]: item for item in before["scripts"]}
    scripts_by_referent = {item["referent"]: item for item in after["scripts"]}
    new_scripts = {item["path"]: item["source"] for item in after["scripts"]}
    for referent, item in old_scripts.items():
        path, source = item["path"], item["source"]
        updated = scripts_by_referent.get(referent)
        if not updated:
            raise ValueError(f"Original script instance disappeared: {referent}")
        if path in REPLACEMENTS:
            expected = (SOURCES / REPLACEMENTS[path]).read_text(encoding="utf-8")
            if updated["source"] != expected:
                raise ValueError(f"Fixed script content mismatch: {path}")
        elif updated["source"] != source:
            raise ValueError(f"Unrelated script changed: {path}")

    required = {
        "ReplicatedStorage/RPGEnhancements/EnhancementConfig",
        "ReplicatedStorage/RPGEnhancements/QuirkMaid",
        "ServerScriptService/RPGEnhancements/SprintController",
        "ServerScriptService/RPGEnhancements/CombatActions",
        "ServerScriptService/RPGEnhancements/NPCEnhancer",
        "ServerScriptService/RPGEnhancements/RPGState",
        "StarterPlayer/StarterPlayerScripts/RPGEnhancedInterface",
        "StarterPlayer/StarterPlayerScripts/QuirkMovement",
    }
    missing = sorted(required - new_scripts.keys())
    if missing:
        raise ValueError(f"Added scripts missing: {missing}")
    for path, script in new_scripts.items():
        if path in REPLACEMENTS or path in required:
            if not script.startswith("--!strict"):
                raise ValueError(f"Script missing strict declaration: {path}")
    imported = [asset for asset in after["assets"] if asset["path"].startswith("ReplicatedStorage/RPGEnhancements/Animations/")]
    if len(imported) != len(DONOR_ANIMATIONS):
        raise ValueError(f"Only found {len(imported)} imported animations")

    return {
        "valid": True,
        "original_instances_preserved": len(before["instances"]),
        "untouched_original_scripts": sum(item["path"] not in REPLACEMENTS for item in old_scripts.values()),
        "fixed_original_scripts": sum(item["path"] in REPLACEMENTS for item in old_scripts.values()),
        "new_scripts": len(required),
        "added_instances": modified_instances - original_instances,
        "new_class_groups": modified_classes - original_classes,
        "quirkbound_animations": len(imported),
        "all_other_original_chunks_preserved": True,
        "bytes": modified_path.stat().st_size,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("donor", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--validate", action="store_true")
    args = parser.parse_args()
    result = validate(args.source, args.output) if args.validate else enhance(args.source, args.donor, args.output)
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
