from typing import Any


def group_type_value(group: dict[str, Any]) -> str:
    return ";".join(str(value) for value in group.get("groupTypes") or [])


def group_row(group: dict[str, Any]) -> list[Any]:
    return [
        group.get("displayName") or "",
        group.get("mail") or "",
        group.get("id") or "",
        group.get("mailEnabled"),
        group.get("securityEnabled"),
        group_type_value(group),
        group.get("createdDateTime") or "",
    ]


def user_row(user: dict[str, Any]) -> list[Any]:
    return [
        user.get("displayName") or "",
        user.get("userPrincipalName") or "",
        user.get("mail") or "",
        user.get("id") or "",
        user.get("accountEnabled"),
    ]


def search_user_row(user: dict[str, Any]) -> list[Any]:
    return [
        user.get("displayName") or "",
        user.get("userPrincipalName") or "",
        user.get("mail") or "",
        user.get("id") or "",
        user.get("accountEnabled"),
        user.get("userType") or "",
        user.get("jobTitle") or "",
        user.get("department") or "",
        user.get("companyName") or "",
        user.get("officeLocation") or "",
    ]


def empty_manager_details() -> dict[str, str]:
    return {"managerDisplayName": "", "managerId": ""}


def manager_details_from_obj(obj: dict[str, Any]) -> dict[str, str]:
    return {
        "managerDisplayName": obj.get("displayName") or "",
        "managerId": obj.get("id") or "",
    }
