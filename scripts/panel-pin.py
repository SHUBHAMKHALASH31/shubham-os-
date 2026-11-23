#!/usr/bin/env python3
# Shubham OS — 2 jobs in the XFCE panel config:
# 1) Pin the ShubhamOS Update launcher to panel-1 (taskbar)
# 2) Add a Mac-like dock at the bottom as panel-2
# Usage: panel-pin.py <xfce4-panel.xml> [applications_dir]
import sys, os
import xml.etree.ElementTree as ET

def find_prop(parent, name):
    for p in parent.findall("property"):
        if p.get("name") == name:
            return p
    return None

def make_prop(name, typ=None, value=None):
    p = ET.Element("property")
    p.set("name", name)
    if typ: p.set("type", typ)
    if value is not None: p.set("value", value)
    return p

def add_value(arr, typ, val):
    v = ET.SubElement(arr, "value")
    v.set("type", typ); v.set("value", str(val))
    return v

def main():
    path = sys.argv[1]
    apps_dir = sys.argv[2] if len(sys.argv) > 2 else "/usr/share/applications"
    if not os.path.isfile(path):
        print("panel-pin: file not found, skip:", path); return
    try:
        tree = ET.parse(path)
    except Exception as e:
        print("panel-pin: XML parse fail, skip:", e); return
    root = tree.getroot()
    plugins = find_prop(root, "plugins")
    panels = find_prop(root, "panels")
    if plugins is None or panels is None:
        print("panel-pin: plugins/panels not found, skip"); return

    ids = []
    for p in plugins.findall("property"):
        n = p.get("name", "")
        if n.startswith("plugin-"):
            try: ids.append(int(n.split("-")[1]))
            except Exception: pass
    next_id = (max(ids) + 1) if ids else 1

    def has_launcher(desktop):
        for p in plugins.findall("property"):
            if p.get("value") == "launcher":
                items = find_prop(p, "items")
                if items is not None:
                    for v in items.findall("value"):
                        if v.get("value") == desktop:
                            return True
        return False

    def new_launcher(desktop):
        nonlocal next_id
        pid = next_id; next_id += 1
        lp = make_prop(f"plugin-{pid}", "string", "launcher")
        items = make_prop("items", "array")
        add_value(items, "string", desktop)
        lp.append(items)
        plugins.append(lp)
        return pid

    def panel_prop(pid_name):
        return find_prop(panels, pid_name)

    def plugin_ids_arr(panel):
        arr = find_prop(panel, "plugin-ids")
        if arr is None:
            arr = make_prop("plugin-ids", "array")
            panel.append(arr)
        return arr

    # --- 1) Pin updater in panel-1 ---
    p1 = panel_prop("panel-1")
    if p1 is not None and not has_launcher("shubham-update.desktop"):
        uid = new_launcher("shubham-update.desktop")
        add_value(plugin_ids_arr(p1), "int", uid)
        print("panel-pin: updater pinned, plugin", uid)

    # --- 2) Mac dock = panel-2 ---
    if panel_prop("panel-2") is None:
        add_value(panels, "int", 2)
        p2 = make_prop("panel-2", "empty")
        p2.append(make_prop("position", "string", "p=8;x=0;y=0"))
        p2.append(make_prop("length", "uint", "1"))
        p2.append(make_prop("length-adjust", "bool", "true"))
        p2.append(make_prop("size", "uint", "44"))
        p2.append(make_prop("icon-size", "uint", "34"))
        p2.append(make_prop("mode", "uint", "0"))
        p2.append(make_prop("autohide-behavior", "uint", "0"))
        p2.append(make_prop("background-style", "uint", "1"))
        p2.append(make_prop("background-alpha", "uint", "70"))
        arr = make_prop("plugin-ids", "array")
        candidates = [
            ["firefox-esr.desktop", "firefox.desktop"],
            ["org.xfce.Thunar.desktop", "thunar.desktop"],
            ["xfce4-terminal.desktop"],
            ["shubham-update.desktop"],
            ["xfce4-settings-manager.desktop"],
        ]
        for group in candidates:
            chosen = None
            for c in group:
                if c == "shubham-update.desktop" or os.path.isfile(os.path.join(apps_dir, c)):
                    chosen = c; break
            if chosen:
                lid = new_launcher(chosen)
                add_value(arr, "int", lid)
        p2.append(arr)
        panels.append(p2)
        print("panel-pin: Mac dock (panel-2) added")

    tree.write(path, encoding="UTF-8", xml_declaration=True)
    print("panel-pin: done ->", path)

main()
