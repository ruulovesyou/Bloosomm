"""Validate built Rojo module hierarchy and all literal script-relative requires."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def check_package(path: Path):
    tree = ET.parse(path)
    nodes, parents, children, sources = {}, {}, {}, {}

    def visit(item, parent=None):
        key = item.attrib['referent']
        name = item.find("./Properties/string[@name='Name']").text
        nodes[key] = (name, item.attrib['class'])
        parents[key] = parent
        children[key] = {}
        if parent is not None:
            assert name not in children[parent], f'Duplicate child {name}'
            children[parent][name] = key
        source = item.find("./Properties/*[@name='Source']")
        if source is not None:
            sources[key] = source.text or ''
        for child in item.findall('Item'):
            visit(child, key)

    for item in tree.getroot().findall('Item'):
        visit(item)
    modules = {key for key, (_, kind) in nodes.items() if kind == 'ModuleScript'}
    expected = len(list((ROOT / 'src/Blossom').rglob('*.luau')))
    assert len(modules) == expected, f'{path.name}: {len(modules)} modules, expected {expected}'
    graph = {key: [] for key in modules}
    for key in modules:
        assert sources.get(key), f'Empty module {nodes[key]}'
        for expression in re.findall(r'require\((script(?:\.\w+)+)\)', sources[key]):
            target = key
            for part in expression.split('.')[1:]:
                target = parents[target] if part == 'Parent' else children[target].get(part)
                assert target is not None, f'{nodes[key]} unresolved: {expression}'
            assert target in modules, f'{expression} does not resolve to a ModuleScript'
            graph[key].append(target)
    visited, active = set(), set()

    def walk(key):
        assert key not in active, f'Cyclic require at {nodes[key]}'
        if key in visited:
            return
        active.add(key)
        for child in graph[key]:
            walk(child)
        active.remove(key)
        visited.add(key)

    for key in modules:
        walk(key)
    local_scripts = [key for key, (_, kind) in nodes.items() if kind == 'LocalScript']
    expected_local = 0 if path.suffix == '.rbxmx' else 1
    assert len(local_scripts) == expected_local
    for key in local_scripts:
        assert sources.get(key), 'Empty client entry point'
    print(f'PASS {path.name}: {len(modules)} modules, {sum(map(len, graph.values()))} resolved dependency edges, no cycles, {len(local_scripts)} client entry points')


for artifact in ['Blossom.rbxmx', 'BlossomDemo.rbxlx', 'BlossomSmokeTests.rbxlx']:
    check_package(ROOT / 'build' / artifact)
