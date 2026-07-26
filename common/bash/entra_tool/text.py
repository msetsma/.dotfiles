import re


def is_guid(value: str) -> bool:
    return bool(
        re.fullmatch(
            r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}",
            value,
        )
    )


def looks_like_bad_guid(value: str) -> bool:
    return bool(
        re.fullmatch(
            r"[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}.+",
            value,
        )
    )


def is_short_hex_id_prefix(value: str) -> bool:
    return bool(re.fullmatch(r"[0-9A-Fa-f]{8,31}", value))


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", value.lower())
    return slug.strip("_")
