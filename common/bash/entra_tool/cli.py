from collections.abc import Callable

from entra_tool.cli_flags import apply_option_arg
from entra_tool.cli_targets import (
    CACHE_TARGETS,
    COMPARE_TARGETS,
    SEARCH_TARGETS,
    parse_target,
)
from entra_tool.cli_usage import USAGE
from entra_tool.errors import die
from entra_tool.models import Options


def parse_args(
    argv: list[str], show_quick_start: Callable[[], None] | None = None
) -> Options:
    if not argv:
        if show_quick_start is not None:
            show_quick_start()
        raise SystemExit(0)
    if argv[0] in ("-h", "--help"):
        print(USAGE)
        raise SystemExit(0)

    args = list(argv)
    opts = parse_target(args)
    while args:
        arg = args.pop(0)
        apply_option_arg(arg, args, opts)
    return opts


def validate_options(opts: Options) -> None:
    if opts.target_type in SEARCH_TARGETS and opts.tsv_output:
        die(
            "--tsv is not supported with search commands; select an object first, then export with user or group mode if needed."
        )

    if opts.target_type in CACHE_TARGETS:
        if opts.tsv_output or opts.fzf_output or opts.mode_explicit or opts.full_output:
            die("cache commands only support --users, --groups, --all, and --color")
        if opts.refresh_cache or not opts.use_cache:
            die("cache commands do not support --refresh-cache or --no-cache")
        if opts.target_type == "cache-status" and opts.cache_scope_explicit:
            die("cache status does not support --users, --groups, or --all")
        if opts.target_type == "cache-refresh" and not (
            opts.cache_users or opts.cache_groups
        ):
            die("cache refresh needs at least one cache scope")
        return

    if opts.target_type in COMPARE_TARGETS:
        if opts.tsv_output or opts.fzf_output or opts.cache_scope_explicit:
            die(
                "compare commands support --direct, --transitive, --full, --refresh-cache, --no-cache, and --color"
            )
        return

    if opts.cache_scope_explicit:
        die("--users, --groups, and --all are only valid with cache refresh")

    if opts.target_type == "dept":
        if opts.mode_explicit:
            die("--direct and --transitive are not supported with dept")
        if opts.fzf_output:
            die(
                "--fzf and --interactive are not supported with dept; dept already opens a picker"
            )

    is_reports = opts.target_type == "reports"
    if (
        opts.target_type not in SEARCH_TARGETS
        and not is_reports
        and (opts.refresh_cache or not opts.use_cache)
    ):
        die(
            "--refresh-cache and --no-cache are only valid with search commands or reports"
        )

    if opts.tsv_output and opts.fzf_output:
        die("--tsv and --fzf cannot be used together")

    if opts.target_type == "reports" and opts.identifier and opts.fzf_output:
        die(
            "--fzf is not supported with direct reports lookup. Run reports without a user to use the picker."
        )
