#!/usr/bin/env python3
"""Static regression checks for the integrated Luau RPG enhancement project."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parent / "improved_rpg"


def check_lexical_balance(path: Path) -> int:
    source = path.read_text(encoding="utf-8")
    stack: list[tuple[str, int]] = []
    pairs = {")": "(", "]": "[", "}": "{"}
    position = 0
    lines = 1
    while position < len(source):
        char = source[position]
        if char == "\n":
            lines += 1
            position += 1
            continue
        if source.startswith("--", position):
            long = re.match(r"--\[(=*)\[", source[position:])
            if long:
                closing = "]" + long.group(1) + "]"
                end = source.find(closing, position + len(long.group(0)))
                if end < 0:
                    raise ValueError(f"{path}:{lines}: unterminated long comment")
                lines += source[position:end].count("\n")
                position = end + len(closing)
            else:
                end = source.find("\n", position)
                position = len(source) if end < 0 else end
            continue
        if char in {"\"", "'", "`"}:
            quote = char
            start_line = lines
            position += 1
            while position < len(source):
                if source[position] == "\\":
                    position += 2
                    continue
                if source[position] == quote:
                    position += 1
                    break
                if source[position] == "\n":
                    if quote != "`":
                        raise ValueError(f"{path}:{start_line}: newline in quoted string")
                    lines += 1
                position += 1
            else:
                raise ValueError(f"{path}:{start_line}: unterminated quoted string")
            continue
        long = re.match(r"\[(=*)\[", source[position:])
        if long:
            closing = "]" + long.group(1) + "]"
            end = source.find(closing, position + len(long.group(0)))
            if end < 0:
                raise ValueError(f"{path}:{lines}: unterminated long string")
            lines += source[position:end].count("\n")
            position = end + len(closing)
            continue
        if char in "([{":
            stack.append((char, lines))
        elif char in ")]}":
            if not stack or stack[-1][0] != pairs[char]:
                raise ValueError(f"{path}:{lines}: mismatched closing delimiter {char!r}")
            stack.pop()
        position += 1
    if stack:
        opening, line = stack[-1]
        raise ValueError(f"{path}:{line}: unclosed delimiter {opening!r}")
    if not source.startswith("--!strict"):
        raise ValueError(f"{path}: strict declaration missing")
    return lines


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def require(marker: str, text: str, purpose: str) -> None:
    if marker not in text:
        raise ValueError(f"Regression: {purpose}")


def main() -> None:
    sources = sorted(ROOT.rglob("*.luau"))
    total_lines = sum(check_lexical_balance(path) for path in sources)
    classes = read("OriginalFixes/Classes.luau")
    races = read("OriginalFixes/Racas.luau")
    quests = read("OriginalFixes/QuestService.luau")
    class_count = len(re.findall(r"^\s*\w+\s*=\s*\{Tipo\s*=", classes, re.MULTILINE))
    race_count = len(re.findall(r"^\s*\w+\s*=\s*\{Raridade\s*=", races, re.MULTILINE))
    quest_count = len(re.findall(r"^\s*quest_\d+\s*=", quests, re.MULTILINE))
    if (class_count, race_count, quest_count) != (20, 12, 16):
        raise ValueError(f"Unexpected RPG content counts: {(class_count, race_count, quest_count)}")

    combat = read("OriginalFixes/CombatHandler.server.luau")
    require("GetPartBoundsInBox", combat, "server-authoritative combat hitbox missing")
    require("requestedLimb:IsDescendantOf(character)", combat, "combat ownership validation missing")
    if ".Touched:Connect" in combat:
        raise ValueError("Regression: unbounded combat touched connections returned")
    controller = read("OriginalFixes/PlayerStatsController.server.luau")
    require('if name == "Energia" then "EnergiaBase"', controller, "energy resource/base-stat separation missing")
    require('player:SetAttribute("DanoBase", derived.DanoBaseFisico)', controller, "original sword damage compatibility missing")
    xp = read("OriginalFixes/XPService.luau")
    require('key == "Money"', xp, "original NPC money rewards are not normalized")
    require('FindFirstChild("LevelUp")', xp, "level-up remote lookup is not explicit")
    sword = read("OriginalFixes/SwordScript.server.luau")
    require('GetAttribute("RPGSwordController")', sword, "duplicate sword-script guard missing")
    npc = read("Server/NPCEnhancer.server.luau")
    require("template:Clone()", npc, "quest enemy respawn missing")
    require('GetAttribute("QuestProgressCredited")', npc, "duplicate quest-credit protection missing")
    datastore = read("OriginalFixes/DataStore.server.luau")
    require("deepCopy(template)", datastore, "deep-copy data isolation missing")
    require("not loadedSafely[player]", datastore, "failed-load save protection missing")
    require("ActiveQuestProgress", datastore, "active quest progress persistence missing")
    require("CustomizationComplete", datastore, "appearance persistence missing")
    customization = read("Server/CharacterCustomization.server.luau")
    for marker, purpose in (
        ('"RaceAssigned"', "birth race assignment missing"),
        ('"RollRace"', "server-authoritative race selection missing"),
        ('"RPGCosmetics"', "visible race cosmetics missing"),
        ("GuaranteedLegendaryAt", "legendary race pity missing"),
        ("Appearance.IsValid", "appearance input validation missing"),
    ):
        require(marker, customization, purpose)
    appearance = read("Shared/CharacterAppearance.luau")
    require("Appearance.RaceAccents", appearance, "per-race cosmetic identity missing")
    brain = read("Shared/EnemyBrain.luau")
    for marker in ("PathfindingService", "Investigando", "alertAllies", "AttackTelegraph", "LeashRange"):
        require(marker, brain, f"advanced enemy behavior missing: {marker}")
    interface = read("Client/RPGInterface.client.luau")
    require('"MedievalCharacterCodex"', interface, "medieval customization codex missing")
    require('"ViewportFrame"', interface, "three-dimensional character preview missing")
    require("progressão automática".lower(), interface.lower(), "automatic progression explanation missing")
    if any(marker in interface for marker in ('"ActionBar"', '"Profile"', '"AllocateStat"', "Enum.Font.Gotham")):
        raise ValueError("Regression: modern hub or manually allocated attributes returned")
    if any(marker in controller + xp + datastore for marker in ("Allocated_", "AttributePoints")):
        raise ValueError("Regression: manual attribute progression returned")
    weights = re.search(r"Racas\.RarityWeights\s*=\s*\{([^}]+)\}", races)
    if not weights:
        raise ValueError("Race rarity weights were not found")
    percentages = [float(number) for number in re.findall(r"=\s*(\d+(?:\.\d+)?|\.\d+)", weights.group(1))]
    if abs(sum(percentages) - 100) > 1e-9:
        raise ValueError(f"Race rarity percentages do not sum to 100: {sum(percentages)}")

    print(
        json.dumps(
            {
                "valid": True,
                "luau_sources": len(sources),
                "lines": total_lines,
                "classes": class_count,
                "races": race_count,
                "quests": quest_count,
                "race_rarity_probability_total": sum(percentages),
                "regression_checks": 28,
            },
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
