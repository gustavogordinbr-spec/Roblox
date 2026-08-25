#!/usr/bin/env python3
"""Inspect and extend Roblox binary .rbxl files without dropping original chunks."""

from __future__ import annotations

import argparse
import ctypes
import ctypes.util
import json
import struct
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass
from pathlib import Path


MAGIC = b"<roblox!\x89\xff\r\n\x1a\n"
LZ4 = ctypes.CDLL(ctypes.util.find_library("lz4"))
LZ4.LZ4_decompress_safe.argtypes = [
    ctypes.c_char_p,
    ctypes.c_char_p,
    ctypes.c_int,
    ctypes.c_int,
]
LZ4.LZ4_decompress_safe.restype = ctypes.c_int
LZ4.LZ4_compress_default.argtypes = [
    ctypes.c_char_p,
    ctypes.c_char_p,
    ctypes.c_int,
    ctypes.c_int,
]
LZ4.LZ4_compress_default.restype = ctypes.c_int
LZ4.LZ4_compressBound.argtypes = [ctypes.c_int]
LZ4.LZ4_compressBound.restype = ctypes.c_int


@dataclass
class Chunk:
    kind: bytes
    compressed: bytes
    decompressed_length: int
    reserved: bytes
    offset: int
    stored_uncompressed: bool = False

    def payload(self) -> bytes:
        if self.stored_uncompressed or self.decompressed_length == 0:
            return self.compressed
        source = ctypes.create_string_buffer(self.compressed)
        target = ctypes.create_string_buffer(self.decompressed_length)
        result = LZ4.LZ4_decompress_safe(
            source, target, len(self.compressed), self.decompressed_length
        )
        if result != self.decompressed_length:
            raise ValueError(
                f"Could not decompress {self.kind!r} at {self.offset}: {result}"
            )
        return target.raw

    def encoded(self) -> bytes:
        return (
            self.kind
            + struct.pack(
                "<II",
                0 if self.stored_uncompressed else len(self.compressed),
                self.decompressed_length,
            )
            + self.reserved
            + self.compressed
        )


class Reader:
    def __init__(self, data: bytes):
        self.data = data
        self.offset = 0

    def u8(self) -> int:
        result = self.data[self.offset]
        self.offset += 1
        return result

    def u32(self) -> int:
        result = struct.unpack_from("<I", self.data, self.offset)[0]
        self.offset += 4
        return result

    def string(self) -> str:
        size = self.u32()
        result = self.data[self.offset : self.offset + size]
        self.offset += size
        return result.decode("utf-8", errors="replace")


def decode_interleaved_ints(data: bytes, count: int, signed: bool = False) -> list[int]:
    result = []
    for index in range(count):
        value = (
            (data[index] << 24)
            | (data[count + index] << 16)
            | (data[2 * count + index] << 8)
            | data[3 * count + index]
        )
        if signed:
            value = -(value >> 1) - 1 if value & 1 else value >> 1
        result.append(value)
    return result


def encode_interleaved_ints(values: list[int], signed: bool = False) -> bytes:
    encoded = []
    for value in values:
        if signed:
            value = (-value * 2 - 1) if value < 0 else value * 2
        value &= 0xFFFFFFFF
        encoded.append(value)
    return bytes(
        (value >> shift) & 0xFF
        for shift in (24, 16, 8, 0)
        for value in encoded
    )


def decode_referents(data: bytes, count: int) -> list[int]:
    deltas = decode_interleaved_ints(data[: 4 * count], count, signed=True)
    values = []
    current = 0
    for delta in deltas:
        current += delta
        values.append(current)
    return values


def encode_referents(values: list[int]) -> bytes:
    previous = 0
    deltas = []
    for value in values:
        deltas.append(value - previous)
        previous = value
    return encode_interleaved_ints(deltas, signed=True)


def encode_string(value: str) -> bytes:
    data = value.encode("utf-8")
    return struct.pack("<I", len(data)) + data


def compressed_chunk(kind: bytes, payload: bytes) -> Chunk:
    if len(payload) < 32:
        return Chunk(kind, payload, len(payload), b"\x00" * 4, 0, True)
    source = ctypes.create_string_buffer(payload)
    capacity = LZ4.LZ4_compressBound(len(payload))
    target = ctypes.create_string_buffer(capacity)
    result = LZ4.LZ4_compress_default(source, target, len(payload), capacity)
    if result <= 0:
        raise ValueError(f"Could not compress {kind!r}")
    return Chunk(kind, target.raw[:result], len(payload), b"\x00" * 4, 0, False)


def inject_rpg(source_path: Path, output_path: Path, source_root: Path) -> dict:
    raw_file = source_path.read_bytes()
    version, class_count, instance_count, chunks = parse_chunks(source_path)
    service_refs = {}
    max_referent = -1
    prnt_index = -1
    for index, chunk in enumerate(chunks):
        if chunk.kind == b"INST":
            reader = Reader(chunk.payload())
            reader.u32()
            class_name = reader.string()
            is_service = reader.u8()
            count = reader.u32()
            refs = decode_referents(reader.data[reader.offset :], count)
            if refs:
                max_referent = max(max_referent, max(refs))
            if is_service and count == 1:
                service_refs[class_name] = refs[0]
        elif chunk.kind == b"PRNT":
            prnt_index = index
    required = {
        "ReplicatedStorage",
        "ServerScriptService",
        "StarterPlayer",
        "StarterPlayerScripts",
    }
    if not {"ReplicatedStorage", "ServerScriptService"}.issubset(service_refs):
        raise ValueError("Required Roblox services were not found")

    starter_player_scripts_ref = None
    for chunk in chunks:
        if chunk.kind != b"INST":
            continue
        reader = Reader(chunk.payload())
        reader.u32()
        class_name = reader.string()
        reader.u8()
        count = reader.u32()
        refs = decode_referents(reader.data[reader.offset :], count)
        if class_name == "StarterPlayerScripts" and refs:
            starter_player_scripts_ref = refs[0]
            break
    if starter_player_scripts_ref is None:
        raise ValueError("StarterPlayerScripts was not found")
    if prnt_index < 0:
        raise ValueError("PRNT chunk was not found")

    next_ref = max_referent + 1
    specs = []

    def add(class_name: str, name: str, parent: int, source_file: Path | None = None) -> int:
        nonlocal next_ref
        ref = next_ref
        next_ref += 1
        source = source_file.read_text(encoding="utf-8") if source_file else None
        specs.append(
            {
                "class": class_name,
                "name": name,
                "parent": parent,
                "ref": ref,
                "source": source,
                "source_file": str(source_file) if source_file else None,
            }
        )
        return ref

    replicated_root = add("Folder", "AuroraRPG", service_refs["ReplicatedStorage"])
    shared_root = add("Folder", "Shared", replicated_root)
    remotes_root = add("Folder", "Remotes", replicated_root)
    shared_files = [
        "GameConfig.luau",
        "ClassDefinitions.luau",
        "ItemDefinitions.luau",
        "AbilityDefinitions.luau",
        "QuestDefinitions.luau",
        "RarityDefinitions.luau",
        "RegionDefinitions.luau",
		"RecipeDefinitions.luau",
		"AchievementDefinitions.luau",
    ]
    for filename in shared_files:
        add("ModuleScript", filename.removesuffix(".luau"), shared_root, source_root / "Shared" / filename)
    for name in ["Action", "StateChanged", "Notification"]:
        add("RemoteEvent", name, remotes_root)
    add("RemoteFunction", "RequestState", remotes_root)

    server_root = add("Folder", "AuroraRPG", service_refs["ServerScriptService"])
    services_root = add("Folder", "Services", server_root)
    server_files = [
        "ProfileService.luau",
        "ProgressionService.luau",
        "InventoryService.luau",
        "QuestService.luau",
        "PartyService.luau",
        "CombatService.luau",
        "NPCService.luau",
        "WorldService.luau",
		"CraftingService.luau",
		"AchievementService.luau",
    ]
    for filename in server_files:
        add("ModuleScript", filename.removesuffix(".luau"), services_root, source_root / "Server" / filename)
    add(
        "Script",
        "AuroraRPGBootstrap",
        server_root,
        source_root / "Server" / "AuroraRPGBootstrap.server.luau",
    )
    add(
        "LocalScript",
        "AuroraRPGClient",
        starter_player_scripts_ref,
        source_root / "Client" / "AuroraRPGClient.client.luau",
    )

    grouped = defaultdict(list)
    for spec in specs:
        grouped[spec["class"]].append(spec)
    inserted = []
    next_class_id = class_count
    manifest_classes = []
    for class_name in ["Folder", "ModuleScript", "RemoteEvent", "RemoteFunction", "Script", "LocalScript"]:
        instances = grouped.get(class_name, [])
        if not instances:
            continue
        class_id = next_class_id
        next_class_id += 1
        refs = [item["ref"] for item in instances]
        inst_payload = (
            struct.pack("<I", class_id)
            + encode_string(class_name)
            + b"\x00"
            + struct.pack("<I", len(instances))
            + encode_referents(refs)
        )
        inserted.append(compressed_chunk(b"INST", inst_payload))
        name_payload = (
            struct.pack("<I", class_id)
            + encode_string("Name")
            + b"\x01"
            + b"".join(encode_string(item["name"]) for item in instances)
        )
        inserted.append(compressed_chunk(b"PROP", name_payload))
        if class_name in {"ModuleScript", "Script", "LocalScript"}:
            source_payload = (
                struct.pack("<I", class_id)
                + encode_string("Source")
                + b"\x01"
                + b"".join(encode_string(item["source"] or "") for item in instances)
            )
            inserted.append(compressed_chunk(b"PROP", source_payload))
        manifest_classes.append({"class_id": class_id, "class": class_name, "count": len(instances)})

    prnt_chunk = chunks[prnt_index]
    reader = Reader(prnt_chunk.payload())
    prnt_version = reader.u8()
    old_count = reader.u32()
    children = decode_referents(reader.data[reader.offset :], old_count)
    reader.offset += 4 * old_count
    parents = decode_referents(reader.data[reader.offset :], old_count)
    children.extend(item["ref"] for item in specs)
    parents.extend(item["parent"] for item in specs)
    prnt_payload = (
        bytes([prnt_version])
        + struct.pack("<I", len(children))
        + encode_referents(children)
        + encode_referents(parents)
    )
    chunks[prnt_index] = compressed_chunk(b"PRNT", prnt_payload)
    chunks[prnt_index:prnt_index] = inserted

    header = bytearray(raw_file[:32])
    struct.pack_into("<HII", header, len(MAGIC), version, next_class_id, instance_count + len(specs))
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("wb") as target:
        target.write(header)
        for chunk in chunks:
            target.write(chunk.encoded())

    return {
        "source": str(source_path),
        "output": str(output_path),
        "original_bytes": source_path.stat().st_size,
        "output_bytes": output_path.stat().st_size,
        "original_classes": class_count,
        "output_classes": next_class_id,
        "original_instances": instance_count,
        "output_instances": instance_count + len(specs),
        "added_instances": len(specs),
        "classes": manifest_classes,
        "instances": [
            {
                "referent": item["ref"],
                "class": item["class"],
                "name": item["name"],
                "parent": item["parent"],
                "source_file": item["source_file"],
            }
            for item in specs
        ],
    }


def parse_chunks(path: Path) -> tuple[int, int, int, list[Chunk]]:
    data = path.read_bytes()
    if not data.startswith(MAGIC):
        raise ValueError("Not a Roblox binary place")
    version, classes, instances = struct.unpack_from("<HII", data, len(MAGIC))
    offset = 32
    chunks = []
    while offset + 16 <= len(data):
        kind = data[offset : offset + 4]
        compressed_length, decompressed_length = struct.unpack_from(
            "<II", data, offset + 4
        )
        reserved = data[offset + 12 : offset + 16]
        start = offset + 16
        stored_uncompressed = compressed_length == 0
        end = start + (decompressed_length if stored_uncompressed else compressed_length)
        if end > len(data):
            raise ValueError(f"Truncated {kind!r} chunk")
        chunks.append(
            Chunk(
                kind,
                data[start:end],
                decompressed_length,
                reserved,
                offset,
                stored_uncompressed,
            )
        )
        offset = end
        if kind == b"END\x00":
            break
    if offset != len(data):
        raise ValueError(f"Trailing or malformed bytes: {len(data) - offset}")
    return version, classes, instances, chunks


def inspect(path: Path) -> dict:
    version, classes, instances, chunks = parse_chunks(path)
    class_info = {}
    names = defaultdict(list)
    sources = []
    parent_info = {}

    for chunk in chunks:
        if chunk.kind == b"INST":
            reader = Reader(chunk.payload())
            class_id = reader.u32()
            class_name = reader.string()
            is_service = reader.u8()
            count = reader.u32()
            referents = decode_referents(reader.data[reader.offset :], count)
            class_info[class_id] = {
                "class": class_name,
                "count": count,
                "service": is_service,
                "referents": referents,
            }
        elif chunk.kind == b"PROP":
            raw = chunk.payload()
            reader = Reader(raw)
            class_id = reader.u32()
            prop_name = reader.string()
            prop_type = reader.u8()
            if prop_name in {"Name", "Source", "Disabled", "RunContext"}:
                if prop_name == "Name" and prop_type == 1 and class_id in class_info:
                    count = class_info[class_id]["count"]
                    for _ in range(min(count, 80)):
                        names[class_id].append(reader.string())
                if prop_name == "Source":
                    sources.append(
                        {
                            "class_id": class_id,
                            "class": class_info.get(class_id, {}).get("class"),
                            "type": prop_type,
                            "payload_bytes": len(raw),
                        }
                    )
        elif chunk.kind == b"PRNT":
            reader = Reader(chunk.payload())
            version_byte = reader.u8()
            count = reader.u32()
            children = decode_referents(reader.data[reader.offset :], count)
            reader.offset += count * 4
            parents = decode_referents(reader.data[reader.offset :], count)
            parent_info = {"version": version_byte, "count": count}
            parent_map = dict(zip(children, parents))

    services = []
    for class_id, item in class_info.items():
        if item["service"]:
            for index, referent in enumerate(item["referents"]):
                services.append(
                    {
                        "class": item["class"],
                        "referent": referent,
                        "name": names[class_id][index] if index < len(names[class_id]) else None,
                        "parent": parent_map.get(referent),
                    }
                )

    merged_class_counts = Counter()
    merged_selected_names = defaultdict(list)
    for class_id, item in class_info.items():
        merged_class_counts[item["class"]] += item["count"]
        if item["class"] in {
            "Script",
            "LocalScript",
            "ModuleScript",
            "RemoteEvent",
            "RemoteFunction",
            "Folder",
            "ScreenGui",
        }:
            merged_selected_names[item["class"]].extend(names[class_id])

    return {
        "path": str(path),
        "bytes": path.stat().st_size,
        "version": version,
        "header_classes": classes,
        "header_instances": instances,
        "chunk_counts": dict(Counter(chunk.kind.decode("ascii", "replace") for chunk in chunks)),
        "class_counts": dict(merged_class_counts.most_common()),
        "selected_names": dict(merged_selected_names),
        "services": services,
        "sources": sources,
        "parent_chunk": parent_info,
    }


def validate(original_path: Path, modified_path: Path) -> dict:
    _, original_class_count, original_instance_count, original_chunks = parse_chunks(original_path)
    _, modified_class_count, modified_instance_count, modified_chunks = parse_chunks(modified_path)
    original_remaining = [chunk for chunk in original_chunks if chunk.kind != b"PRNT"]
    modified_original = [
        chunk
        for chunk in modified_chunks
        if chunk.kind != b"PRNT" and not (
            chunk.kind in {b"INST", b"PROP"}
            and struct.unpack_from("<I", chunk.payload(), 0)[0] >= original_class_count
        )
    ]
    if len(original_remaining) != len(modified_original):
        raise ValueError("Original chunk count changed")
    for old, new in zip(original_remaining, modified_original):
        if old.encoded() != new.encoded():
            raise ValueError(f"Original {old.kind!r} chunk was modified")

    def read_graph(chunks: list[Chunk]) -> tuple[dict[int, str], dict[int, int], dict[int, dict]]:
        classes = {}
        instances = {}
        parents = {}
        for chunk in chunks:
            if chunk.kind == b"INST":
                reader = Reader(chunk.payload())
                class_id = reader.u32()
                class_name = reader.string()
                reader.u8()
                count = reader.u32()
                refs = decode_referents(reader.data[reader.offset :], count)
                classes[class_id] = {"name": class_name, "refs": refs}
                for ref in refs:
                    if ref in instances:
                        raise ValueError(f"Duplicate instance referent {ref}")
                    instances[ref] = class_name
            elif chunk.kind == b"PRNT":
                reader = Reader(chunk.payload())
                reader.u8()
                count = reader.u32()
                refs = decode_referents(reader.data[reader.offset :], count)
                reader.offset += 4 * count
                values = decode_referents(reader.data[reader.offset :], count)
                parents = dict(zip(refs, values))
        return instances, parents, classes

    old_instances, old_parents, _ = read_graph(original_chunks)
    new_instances, new_parents, new_classes = read_graph(modified_chunks)
    if len(new_classes) != modified_class_count:
        raise ValueError("Class count does not match header")
    if len(new_instances) != modified_instance_count or len(new_parents) != modified_instance_count:
        raise ValueError("Instance/parent count does not match header")
    for ref, class_name in old_instances.items():
        if new_instances.get(ref) != class_name or new_parents.get(ref) != old_parents.get(ref):
            raise ValueError(f"Original instance {ref} was changed")

    new_props = {}
    for chunk in modified_chunks:
        if chunk.kind != b"PROP":
            continue
        reader = Reader(chunk.payload())
        class_id = reader.u32()
        if class_id < original_class_count:
            continue
        property_name = reader.string()
        property_type = reader.u8()
        if property_type != 1:
            continue
        count = len(new_classes[class_id]["refs"])
        values = [reader.string() for _ in range(count)]
        new_props.setdefault(class_id, {})[property_name] = values

    inserted = []
    source_count = 0
    source_bytes = 0
    for class_id, info in new_classes.items():
        if class_id < original_class_count:
            continue
        properties = new_props.get(class_id, {})
        names = properties.get("Name", [])
        sources = properties.get("Source", [])
        if len(names) != len(info["refs"]):
            raise ValueError(f"Missing Name property for class {info['name']}")
        if info["name"] in {"Script", "LocalScript", "ModuleScript"}:
            if len(sources) != len(info["refs"]):
                raise ValueError(f"Missing Source property for class {info['name']}")
            for source in sources:
                if not source.startswith("--!strict"):
                    raise ValueError("Inserted Luau script is missing --!strict")
                source_count += 1
                source_bytes += len(source.encode("utf-8"))
        for index, ref in enumerate(info["refs"]):
            parent = new_parents[ref]
            if parent != -1 and parent not in new_instances:
                raise ValueError(f"Invalid parent {parent} for {names[index]}")
            inserted.append({"class": info["name"], "name": names[index], "parent": parent})

    required_names = {
        "GameConfig", "ClassDefinitions", "ItemDefinitions", "AbilityDefinitions",
        "QuestDefinitions", "RecipeDefinitions", "AchievementDefinitions",
        "ProfileService", "ProgressionService", "InventoryService", "QuestService",
        "PartyService", "CombatService", "NPCService", "WorldService",
        "CraftingService", "AchievementService", "AuroraRPGBootstrap",
        "AuroraRPGClient", "Action", "StateChanged", "Notification", "RequestState",
    }
    actual_names = {item["name"] for item in inserted}
    missing = sorted(required_names - actual_names)
    if missing:
        raise ValueError(f"Missing RPG instances: {missing}")

    return {
        "valid": True,
        "original_instances_preserved": len(old_instances),
        "original_chunks_preserved": len(original_remaining),
        "original_classes": original_class_count,
        "modified_classes": modified_class_count,
        "added_instances": modified_instance_count - original_instance_count,
        "inserted_script_count": source_count,
        "inserted_source_bytes": source_bytes,
        "output_bytes": modified_path.stat().st_size,
        "inserted_instances": inserted,
    }


def hierarchy(path: Path) -> dict:
    _, _, _, chunks = parse_chunks(path)
    class_info = {}
    selected = {
        "Folder",
        "Script",
        "LocalScript",
        "ModuleScript",
        "ScreenGui",
        "RemoteEvent",
        "RemoteFunction",
        "StarterPlayerScripts",
        "StarterCharacterScripts",
        "Workspace",
        "ReplicatedStorage",
        "ServerScriptService",
        "ServerStorage",
        "StarterGui",
        "StarterPlayer",
    }
    referent_info = {}
    parents = {}
    for chunk in chunks:
        if chunk.kind == b"INST":
            reader = Reader(chunk.payload())
            class_id = reader.u32()
            class_name = reader.string()
            reader.u8()
            count = reader.u32()
            refs = decode_referents(reader.data[reader.offset :], count)
            class_info[class_id] = (class_name, refs)
            if class_name in selected:
                for ref in refs:
                    referent_info[ref] = {"class": class_name, "name": class_name}
        elif chunk.kind == b"PROP":
            reader = Reader(chunk.payload())
            class_id = reader.u32()
            prop = reader.string()
            prop_type = reader.u8()
            if prop == "Name" and prop_type == 1 and class_id in class_info:
                class_name, refs = class_info[class_id]
                if class_name in selected:
                    for ref in refs:
                        referent_info[ref]["name"] = reader.string()
        elif chunk.kind == b"PRNT":
            reader = Reader(chunk.payload())
            reader.u8()
            count = reader.u32()
            refs = decode_referents(reader.data[reader.offset :], count)
            reader.offset += 4 * count
            parent_refs = decode_referents(reader.data[reader.offset :], count)
            parents = dict(zip(refs, parent_refs))

    output = {}
    service_classes = {
        "Workspace",
        "ReplicatedStorage",
        "ServerScriptService",
        "ServerStorage",
        "StarterGui",
        "StarterPlayer",
    }
    service_refs = {
        ref: info["class"]
        for ref, info in referent_info.items()
        if info["class"] in service_classes
    }
    for ref, info in referent_info.items():
        chain = []
        current = ref
        while current in parents and len(chain) < 4:
            chain.append(referent_info.get(current, {}).get("name", str(current)))
            current = parents[current]
            if current in service_refs:
                service = service_refs[current]
                if len(chain) <= 2:
                    output.setdefault(service, []).append(
                        {
                            "path": "/".join(reversed(chain)),
                            "class": info["class"],
                            "referent": ref,
                        }
                    )
                break
    for service in output:
        output[service].sort(key=lambda item: item["path"])
        output[service] = output[service][:150]
    return output


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["inspect", "hierarchy", "inject", "validate"])
    parser.add_argument("path", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--sources", type=Path)
    args = parser.parse_args()
    if args.command == "inject":
        if not args.output or not args.sources:
            parser.error("inject requires --output and --sources")
        result = inject_rpg(args.path, args.output, args.sources)
    elif args.command == "validate":
        if not args.output:
            parser.error("validate requires --output")
        result = validate(args.path, args.output)
    else:
        action = inspect if args.command == "inspect" else hierarchy
        result = action(args.path)
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
