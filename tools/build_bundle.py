"""Build Blossom single-file bundle from Bloosoom UI Library/Source/Blossom."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "Bloosoom UI Library" / "Source" / "Blossom"
DEST1 = SOURCE_DIR / "Blossom.lua"
DEST2 = ROOT / "Bloosoom UI Library" / "Blossom.lua"
DEST3 = ROOT / "Blossom" / "Blossom.lua"


def build():
    assert SOURCE_DIR.is_dir(), f"Source directory not found: {SOURCE_DIR}"
    init_path = SOURCE_DIR / "init.luau"
    assert init_path.is_file(), f"init.luau not found: {init_path}"
    init_source = init_path.read_text(encoding="utf-8")

    modules = []
    for file_path in SOURCE_DIR.rglob("*.luau"):
        if file_path == init_path:
            continue
        rel = file_path.relative_to(SOURCE_DIR)
        parts = rel.parts
        folder = parts[0] if len(parts) > 1 else None
        name = file_path.stem
        source = file_path.read_text(encoding="utf-8")
        modules.append((folder, name, source))

    rank = {"Core": 1, "Themes": 2, "Components": 3}
    modules.sort(key=lambda m: (rank.get(m[0], 99), m[0] or "", m[1]))

    chunks = [
        "-- Blossom UI Library - single-file bundle (generated)\n",
        "-- Recreates the script.Core / script.Components / script.Themes tree so the\n",
        "-- original require(script.Parent...) paths work under loadstring.\n\n",
        "local function __node(name, parent)\n",
        "    local node = {Name = name, Parent = parent, _children = {}}\n",
        "    return setmetatable(node, {__index = function(_, key) return node._children[key] end})\n",
        "end\n\n",
        "local __root = __node(\"Blossom\", nil)\n\n",
        "local function __register(folder, name, factory)\n",
        "    local parent = __root\n",
        "    if folder then\n",
        "        parent = __root._children[folder]\n",
        "        if not parent then\n",
        "            parent = __node(folder, __root)\n",
        "            __root._children[folder] = parent\n",
        "        end\n",
        "    end\n",
        "    local leaf = __node(name, parent)\n",
        "    leaf._factory = factory\n",
        "    parent._children[name] = leaf\n",
        "end\n\n",
        "local function __require(node)\n",
        "    if type(node) ~= \"table\" or not node._factory then\n",
        "        error(\"Blossom bundle: require target is not a module\", 2)\n",
        "    end\n",
        "    if not node._loaded then\n",
        "        node._result = node._factory(node, __require)\n",
        "        node._loaded = true\n",
        "    end\n",
        "    return node._result\n",
        "end\n\n",
    ]

    for folder, name, source in modules:
        if folder:
            chunks.append(f'__register("{folder}", "{name}", function(script, require)\n')
        else:
            chunks.append(f'__register(nil, "{name}", function(script, require)\n')
        chunks.append(source)
        chunks.append("\nend)\n\n")

    chunks.append("local function __init(script, require)\n")
    chunks.append(init_source)
    chunks.append("\nend\n\nreturn __init(__root, __require)\n")

    output = "".join(chunks)

    DEST1.write_text(output, encoding="utf-8")
    DEST2.write_text(output, encoding="utf-8")
    if DEST3.parent.is_dir():
        DEST3.write_text(output, encoding="utf-8")
    print(f"PASS generated bundle: {DEST1.name} ({len(output)} bytes, {len(modules) + 1} modules)")


if __name__ == "__main__":
    build()
