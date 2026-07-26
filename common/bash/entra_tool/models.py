from dataclasses import dataclass


@dataclass
class Options:
    target_type: str
    identifier: str = ""
    initial_query: str = ""
    mode: str = "transitive"
    tsv_output: bool = False
    fzf_output: bool = False
    color_mode: str = "auto"
    full_output: bool = False
    name_width_cap: int = 56
    use_cache: bool = True
    refresh_cache: bool = False
    mode_explicit: bool = False
    cache_users: bool = True
    cache_groups: bool = True
    cache_scope_explicit: bool = False
    left_identifier: str = ""
    right_identifier: str = ""


@dataclass
class State:
    user_id: str = ""
    user_display_name: str = ""
    user_upn: str = ""
    group_id: str = ""
    group_display_name: str = ""
    group_mail: str = ""


@dataclass
class CompareSubject:
    kind: str
    object_id: str
    name: str
    detail: str = ""
