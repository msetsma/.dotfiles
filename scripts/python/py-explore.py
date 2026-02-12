#!/usr/bin/env python3

"""
py-explore - Explore Python namespaces interactively

Phase 10:
- Adds --scope=visible to list what modules/packages are importable
  from the current working directory's perspective.
"""

import argparse
import importlib
import importlib.metadata
import inspect
import json
import os
import pkgutil
import sys
from pathlib import Path
from typing import Any

VERSION = "0.10.0"

# ---------------- Env Awareness ---------------- #

def detect_color_mode(mode: str | None) -> bool:
    if mode == "always":
        return True
    if mode == "never":
        return False
    if os.getenv("NO_COLOR") is not None:
        return False
    return sys.stdout.isatty()

# ---------------- Utilities ---------------- #

def safe_import(name: str, extra_path: str | None = None) -> Any | None:
    try:
        if extra_path and extra_path not in sys.path:
            sys.path.insert(0, extra_path)
        return importlib.import_module(name)
    except ImportError as e:
        print(f"[ERR] cannot import {name}: {e}", file=sys.stderr)
        return None

def discover_local_modules() -> list[str]:
    return sorted(f.stem for f in Path(".").glob("*.py") if f.name != "__init__.py")

def discover_local_packages() -> list[str]:
    return sorted(d.name for d in Path(".").glob("*/") if (Path(d) / "__init__.py").exists())

def list_stdlib() -> list[str]:
    return sorted(sys.stdlib_module_names)

def list_site_packages() -> list[dict[str, Any]]:
    results = []
    for dist in importlib.metadata.distributions():
        name = dist.metadata.get("Name", dist._path.name)
        version = dist.version
        tops: list[str] = []
        try:
            txt = dist.read_text("top_level.txt")
            if txt:
                tops = [line.strip() for line in txt.splitlines() if line.strip()]
        except Exception:
            pass
        results.append({"package": name, "version": version, "modules": tops})
    return sorted(results, key=lambda r: r["package"].lower())

def list_visible_imports() -> list[str]:
    """Return what is importable from the current working directory perspective."""
    search_paths = [os.getcwd()] + sys.path[1:]
    return sorted({m.name for m in pkgutil.iter_modules(search_paths)})

# ---------------- Deep Exploration ---------------- #

def explore_object(
    obj: Any,
    name: str = "",
    prefix: str = "",
    deep: bool = False,
    funcs_only: bool = False,
    classes_only: bool = False,
    modules_only: bool = False,
) -> list[dict[str, str]]:
    results: list[dict[str, str]] = []
    if name:
        typ = type(obj).__name__
        results.append({"name": f"{prefix}{name}", "type": typ, "error": ""})

        if funcs_only and not (inspect.isfunction(obj) or inspect.ismethod(obj) or callable(obj)):
            return []
        if classes_only and not inspect.isclass(obj):
            return []
        if modules_only and not inspect.ismodule(obj):
            return []

    try:
        attrs = sorted(a for a in dir(obj) if not a.startswith("_"))
        for attr in attrs:
            try:
                child = getattr(obj, attr)
                if deep:
                    results.extend(
                        explore_object(
                            child,
                            attr,
                            prefix + "  ",
                            deep=deep,
                            funcs_only=funcs_only,
                            classes_only=classes_only,
                            modules_only=modules_only,
                        )
                    )
                else:
                    if funcs_only and not (inspect.isfunction(child) or inspect.ismethod(child)):
                        continue
                    if classes_only and not inspect.isclass(child):
                        continue
                    if modules_only and not inspect.ismodule(child):
                        continue
                    results.append({"name": f"{prefix}  {attr}", "type": type(child).__name__, "error": ""})
            except Exception as e:
                results.append({"name": f"{prefix}  {attr}", "type": "", "error": str(e)[:50]})
    except Exception:
        pass

    return results

# ---------------- Output Renderers ---------------- #

def render_human(records: list[dict[str, str]], color: bool) -> None:
    for rec in records:
        name, typ, err = rec["name"], rec.get("type", ""), rec.get("error", "")
        if err:
            msg = f"{name} -> Error: {err}"
            if color:
                msg = f"\033[31m{msg}\033[0m"
            print(msg)
            continue
        msg = f"{name} -> {typ}"
        if color:
            if typ == "module":
                msg = f"\033[36m{msg}\033[0m"
            elif typ == "type":
                msg = f"\033[33m{msg}\033[0m"
            elif "function" in typ.lower() or "method" in typ.lower():
                msg = f"\033[32m{msg}\033[0m"
        print(msg)

def render_plain(records: list[dict[str, str]]) -> None:
    for rec in records:
        err = rec.get("error")
        if err:
            print(f"{rec['name']}=ERR:{err}")
        else:
            print(f"{rec['name']}={rec['type']}")

def render_json(records: list[dict[str, str]]) -> None:
    print(json.dumps(records, indent=2, ensure_ascii=False))

def _render(records: list[dict[str,str]], fmt: str, color: bool) -> None:
    if fmt == "plain":
        render_plain(records)
    elif fmt == "json":
        render_json(records)
    else:
        render_human(records, color)

# ---------------- Handlers ---------------- #

def handle_package(package: str, fmt: str, color: bool, deep: bool,
                   funcs_only: bool, classes_only: bool, modules_only: bool,
                   extra_path: str | None) -> int:
    mod = safe_import(package, extra_path)
    if not mod:
        return 1
    records = explore_object(mod, package, deep=deep,
                             funcs_only=funcs_only,
                             classes_only=classes_only,
                             modules_only=modules_only)
    _render(records, fmt, color)
    return 0

def handle_scope(scope: str, fmt: str, color: bool) -> int:
    if scope == "stdlib":
        modules = list_stdlib()
        if fmt == "json":
            print(json.dumps({"stdlib": modules}, indent=2))
        elif fmt == "plain":
            for m in modules: print(f"stdlib={m}")
        else:
            print("Stdlib modules:")
            for m in modules: print(f"  - {m}")
        return 0
    if scope == "site":
        packages = list_site_packages()
        if fmt == "json":
            print(json.dumps({"site": packages}, indent=2, ensure_ascii=False))
        elif fmt == "plain":
            for pkg in packages:
                print(f"site={pkg['package']}:{pkg['version']}")
                for mod in pkg["modules"]:
                    print(f"  module={mod}")
        else:
            print("Site packages:")
            for pkg in packages:
                print(f"{pkg['package']} ({pkg['version']})")
                for mod in pkg["modules"]: print(f"  - {mod}")
        return 0
    if scope == "all":
        local_mods, local_pkgs = discover_local_modules(), discover_local_packages()
        stdlib_mods, site_pkgs = list_stdlib(), list_site_packages()
        if fmt == "json":
            data = {"local": {"modules": local_mods, "packages": local_pkgs},
                    "stdlib": stdlib_mods,
                    "site": site_pkgs}
            print(json.dumps(data, indent=2, ensure_ascii=False))
        elif fmt == "plain":
            for m in local_mods: print(f"local_module={m}")
            for p in local_pkgs: print(f"local_package={p}")
            for m in stdlib_mods: print(f"stdlib={m}")
            for pkg in site_pkgs:
                print(f"site={pkg['package']}:{pkg['version']}")
                for mod in pkg["modules"]: print(f"  module={mod}")
        else:
            print("== Local ==")
            for m in local_mods: print(f"  module: {m}")
            for p in local_pkgs: print(f"  package: {p}")
            print("\n== Stdlib ==")
            for m in stdlib_mods: print(f"  {m}")
            print("\n== Site packages ==")
            for pkg in site_pkgs:
                print(f"{pkg['package']} ({pkg['version']})")
                for mod in pkg["modules"]: print(f"  - {mod}")
        return 0
    if scope == "visible":
        modules = list_visible_imports()
        if fmt == "json":
            print(json.dumps({"visible": modules}, indent=2))
        elif fmt == "plain":
            for m in modules: print(f"visible={m}")
        else:
            print("Visible modules/packages from here:")
            for m in modules: print(f"  - {m}")
        return 0
    # fallback: local
    local_mods, local_pkgs = discover_local_modules(), discover_local_packages()
    if fmt == "json":
        print(json.dumps({"modules": local_mods, "packages": local_pkgs}, indent=2))
    elif fmt == "plain":
        for m in local_mods: print(f"module={m}")
        for p in local_pkgs: print(f"package={p}")
    else:
        print("Exploring current directory scope:\n")
        print("Local Python modules:")
        if not local_mods:
            print("  (none found)")
        for m in local_mods:
            if safe_import(m):
                print(f"  - {m}")
        print("\nLocal Python packages:")
        if not local_pkgs:
            print("  (none found)")
        for p in local_pkgs:
            if safe_import(p):
                print(f"  - {p}")
    return 0

# ---------------- CLI ---------------- #

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="py-explore",
        description="Explore Python namespaces interactively.",
        epilog="""Examples:
  py-explore requests                explore module shallow
  py-explore requests --deep         explore top-level API
  py-explore --scope=site --plain    list pip-installed packages
  py-explore --scope=visible         see what is importable here (cwd)
""",
        formatter_class=argparse.RawTextHelpFormatter,
    )
    parser.add_argument("package", nargs="?", help="module/package to explore")
    parser.add_argument("-V", "--version", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--plain", action="store_true")
    parser.add_argument("--color", choices=["auto","always","never"], default="auto")
    parser.add_argument("--scope", choices=["local","stdlib","site","all","visible"], default="local")
    parser.add_argument("--deep", action="store_true", help="explore module attributes recursively")
    parser.add_argument("--funcs", action="store_true", help="show only functions")
    parser.add_argument("--classes", action="store_true", help="show only classes")
    parser.add_argument("--modules", action="store_true", help="show only modules")
    parser.add_argument("--path", help="extra path to add to sys.path before importing")

    args = parser.parse_args(argv)

    fmt = "human"
    if args.json:
        fmt = "json"
    elif args.plain:
        fmt = "plain"

    color = detect_color_mode(args.color)

    if args.version:
        print(f"py-explore {VERSION}")
        return 0

    if args.package:
        return handle_package(
            args.package, fmt, color,
            deep=args.deep,
            funcs_only=args.funcs,
            classes_only=args.classes,
            modules_only=args.modules,
            extra_path=args.path,
        )

    return handle_scope(args.scope, fmt, color)

if __name__ == "__main__":
    sys.exit(main())