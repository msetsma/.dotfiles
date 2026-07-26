from entra_tool.cli_usage import USAGE
from entra_tool.errors import die
from entra_tool.models import Options


def enable_cache_scope(opts: Options) -> None:
    if not opts.cache_scope_explicit:
        opts.cache_users = False
        opts.cache_groups = False
        opts.cache_scope_explicit = True


def apply_option_arg(arg: str, args: list[str], opts: Options) -> None:
    if arg == "--direct":
        opts.mode = "direct"
        opts.mode_explicit = True
    elif arg == "--transitive":
        opts.mode = "transitive"
        opts.mode_explicit = True
    elif arg == "--tsv":
        opts.tsv_output = True
    elif arg in ("--fzf", "--interactive"):
        opts.fzf_output = True
    elif arg == "--full":
        opts.full_output = True
    elif arg == "--refresh-cache":
        opts.refresh_cache = True
    elif arg == "--no-cache":
        opts.use_cache = False
    elif arg == "--color":
        if not args:
            die("--color requires one of: auto, always, never")
        opts.color_mode = args.pop(0)
    elif arg in ("--color=auto", "--color=always", "--color=never"):
        opts.color_mode = arg.split("=", 1)[1]
    elif arg == "--no-color":
        opts.color_mode = "never"
    elif arg == "--users":
        enable_cache_scope(opts)
        opts.cache_users = True
    elif arg == "--groups":
        enable_cache_scope(opts)
        opts.cache_groups = True
    elif arg == "--all":
        opts.cache_scope_explicit = True
        opts.cache_users = True
        opts.cache_groups = True
    elif arg == "--out":
        die(
            "--out was removed. Use --tsv; the script generates the filename automatically."
        )
    elif arg in ("-h", "--help"):
        print(USAGE)
        raise SystemExit(0)
    else:
        die(f"Unknown argument: {arg}")
