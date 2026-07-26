from typing import Any

from entra_tool.terminal import clean, yn


def report_queue_item(
    user: dict[str, Any],
    level: int,
    manager_id: str = "",
    manager_display_name: str = "",
) -> dict[str, Any]:
    return {
        "id": user.get("id") or "",
        "level": level,
        "managerId": manager_id,
        "managerDisplayName": manager_display_name,
        "displayName": user.get("displayName") or "",
        "userPrincipalName": user.get("userPrincipalName") or "",
        "mail": user.get("mail") or "",
        "jobTitle": user.get("jobTitle") or "",
        "department": user.get("department") or "",
        "accountEnabled": ""
        if user.get("accountEnabled") is None
        else user.get("accountEnabled"),
    }


def report_has_title(user: dict[str, Any]) -> bool:
    return bool(clean(user.get("jobTitle")).strip("- "))


def report_is_enabled(user: dict[str, Any]) -> bool:
    return yn(user.get("accountEnabled")) != "N"


def report_is_visible(user: dict[str, Any]) -> bool:
    return report_has_title(user) and report_is_enabled(user)


def report_sort_key(user: dict[str, Any]) -> tuple[str, str]:
    return (clean(user.get("displayName")).lower(), clean(user.get("id")).lower())


def report_display_name(user: dict[str, Any]) -> str:
    return clean(user.get("displayName") or user.get("mail") or user.get("id"))


def build_visible_report_rows(
    root_id: str,
    users: dict[str, dict[str, Any]],
    children_by_manager: dict[str, list[dict[str, Any]]],
) -> list[list[Any]]:
    rows: list[list[Any]] = []

    def visible_children(parent_id: str) -> list[dict[str, Any]]:
        visible: list[dict[str, Any]] = []
        for child in sorted(
            children_by_manager.get(parent_id, []), key=report_sort_key
        ):
            child_id = child.get("id") or ""
            if not child_id:
                continue
            if report_is_visible(child):
                visible.append(child)
            else:
                visible.extend(visible_children(child_id))
        return visible

    def append_row(user: dict[str, Any], visible_level: int, tree_name: str) -> None:
        rows.append(
            [
                visible_level,
                user.get("managerId") or "",
                user.get("managerDisplayName") or "",
                user.get("id") or "",
                user.get("displayName") or "",
                user.get("userPrincipalName") or "",
                user.get("mail") or "",
                user.get("jobTitle") or "",
                user.get("department") or "",
                user.get("accountEnabled"),
                user.get("directReportCount", ""),
                tree_name,
            ]
        )

    def walk(
        user: dict[str, Any],
        visible_level: int,
        prefix: str,
        is_last: bool,
        is_root: bool = False,
    ) -> None:
        name = report_display_name(user)
        if is_root:
            tree_name = name
            child_prefix = ""
        else:
            connector = "└── " if is_last else "├── "
            tree_name = f"{prefix}{connector}{name}"
            child_prefix = prefix + ("    " if is_last else "│   ")

        append_row(user, visible_level, tree_name)
        children = visible_children(user.get("id") or "")
        for index, child in enumerate(children):
            walk(child, visible_level + 1, child_prefix, index == len(children) - 1)

    root = users.get(root_id)
    if root and report_is_visible(root):
        walk(root, 0, "", True, True)
    elif root:
        children = visible_children(root_id)
        for index, child in enumerate(children):
            walk(child, 0, "", index == len(children) - 1)

    return rows
