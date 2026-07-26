from entra_tool.terminal_colors import COLORS, set_colors, setup_color, styled


def print_quick_start() -> None:
    set_colors(setup_color("auto"))

    command_rows = [
        ("entra users [name]", "Search users, then show details and groups"),
        ("entra groups [name]", "Search groups, then show details and users"),
        ("entra dept [name]", "Search departments, then show users and summary"),
        ("entra reports [name-or-upn]", "Show an org/reporting tree"),
        ("entra user <upn-or-id>", "Show a user's groups"),
        ("entra group <name-or-id>", "Show a group's users"),
        ("entra compare users", "Pick two users and compare their groups"),
        ("entra compare groups", "Pick two groups and compare their users"),
    ]
    flag_rows = [
        ("--direct", "Only direct membership or reports"),
        ("--tsv", "Write the generated TSV file"),
        ("--full", "Do not cap long display names"),
        ("--refresh-cache", "Rebuild search picker cache"),
    ]
    examples = [
        "entra users Velasquez",
        "entra dept Engineering",
        'entra groups "Data Science Practice"',
        "entra compare users",
        'entra compare-groups "Group A" "Group B"',
        "entra user person@example.com --direct",
        "entra reports manager@example.com --tsv",
    ]

    print(styled("Entra membership lookup", COLORS.bold, COLORS.cyan))
    print(
        styled(
            "Search users, groups, and reporting trees from Microsoft Entra ID.",
            COLORS.dim,
        )
    )
    print()
    print(styled("Common commands", COLORS.bold))
    for command, description in command_rows:
        print(f"  {styled(f'{command:<32}', COLORS.green)} {description}")
    print()
    print(styled("Useful flags", COLORS.bold))
    for flag, description in flag_rows:
        print(f"  {styled(f'{flag:<32}', COLORS.yellow)} {description}")
    print()
    print(styled("Examples", COLORS.bold))
    for example in examples:
        print(f"  {styled(example, COLORS.dim)}")
    print()
    print(f"Run {styled('entra --help', COLORS.cyan)} for the full command reference.")
