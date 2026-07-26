import shutil
import sys

from entra_tool.cache_commands import print_cache_status, refresh_cache
from entra_tool.cli import parse_args, validate_options
from entra_tool.cli_targets import COMPARE_TARGETS, FIRST_ARGUMENT_ERROR, SEARCH_TARGETS
from entra_tool.command_handlers import (
    run_compare_command,
    run_group_command,
    run_report_command,
    run_search_command,
    run_user_command,
)
from entra_tool.errors import AppError, die
from entra_tool.models import Options, State
from entra_tool.quick_start import print_quick_start
from entra_tool.terminal_colors import set_colors, setup_color


def need_command(command: str) -> None:
    if shutil.which(command) is None:
        die(f"Missing required command: {command}")


def requires_fzf(opts: Options) -> bool:
    if opts.fzf_output or opts.target_type == "compare":
        return True
    if opts.target_type in {"compare-users", "compare-groups"}:
        return not opts.left_identifier or not opts.right_identifier
    if opts.target_type in SEARCH_TARGETS:
        return True
    return opts.target_type == "reports" and not opts.identifier


def run(opts: Options) -> None:
    validate_options(opts)
    try:
        set_colors(setup_color(opts.color_mode))
    except ValueError as exc:
        die(str(exc))
    if opts.target_type == "cache-status":
        print_cache_status()
        return

    need_command("az")
    if opts.target_type == "cache-refresh":
        refresh_cache(opts)
        return

    if requires_fzf(opts):
        need_command("fzf")

    state = State()

    if opts.target_type == "user":
        run_user_command(opts, state)
    elif opts.target_type == "group":
        run_group_command(opts, state)
    elif opts.target_type == "reports":
        run_report_command(opts, state)
    elif opts.target_type in COMPARE_TARGETS:
        run_compare_command(opts)
    elif opts.target_type in SEARCH_TARGETS:
        run_search_command(opts, state)
    else:
        die(FIRST_ARGUMENT_ERROR)


def main(argv: list[str]) -> int:
    try:
        opts = parse_args(argv, print_quick_start)
        run(opts)
        return 0
    except BrokenPipeError:
        return 0
    except AppError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
