from entra_tool.models import State
from entra_tool.text import slugify


def user_groups_tsv_path(state: State, mode: str) -> str:
    slug = slugify(state.user_upn)
    return f"{slug or 'user'}.{mode}.groups.tsv"


def group_users_tsv_path(state: State, mode: str) -> str:
    slug = slugify(state.group_display_name)
    return f"{slug or 'group'}_{state.group_id[:8]}.{mode}.users.tsv"


def reports_tsv_path(state: State, mode: str) -> str:
    slug = slugify(state.user_upn)
    return f"{slug or 'user'}.{mode}.reports.tsv"
