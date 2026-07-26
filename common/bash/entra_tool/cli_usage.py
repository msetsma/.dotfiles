USAGE = """Usage:
  entra user <user-upn-or-id> [--direct|--transitive] [--tsv|--fzf|--interactive] [--full] [--color=auto|always|never]
  entra group <group-display-name-or-id> [--direct|--transitive] [--tsv|--fzf|--interactive] [--full] [--color=auto|always|never]
  entra reports [user-upn-or-id|initial-query] [--direct|--transitive] [--tsv] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra users [initial-query] [--direct|--transitive] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra groups [initial-query] [--direct|--transitive] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra compare [users|groups] [first-id-or-name] [second-id-or-name] [--direct|--transitive] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra compare-users [first-user-upn-or-id] [second-user-upn-or-id] [--direct|--transitive] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra compare-groups [first-group-name-or-id] [second-group-name-or-id] [--direct|--transitive] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra dept [initial-query] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra search [initial-query] [--direct|--transitive] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra search-groups [initial-query] [--direct|--transitive] [--full] [--refresh-cache|--no-cache] [--color=auto|always|never]
  entra cache status
  entra cache refresh [--users] [--groups] [--all]

Output:
  Default mode prints a readable, colorized terminal table.
  --tsv writes a TSV file and prints nothing unless there is an error.
  --interactive, also accepted as --fzf, opens a searchable row picker:
        user -> pick one group -> print that group's users
        group -> pick one user  -> print that user's groups
  users, also accepted as search, opens a searchable user picker, then prints user details and groups.
  groups, also accepted as search-groups, opens a searchable group picker, then prints group details and users.
  compare opens searchable pickers for two users or two groups, then highlights shared
  and different memberships.
  dept opens a searchable department picker, then prints department summary and users.
  reports walks the manager/directReports org tree under a user. With no exact user,
  it opens the cached searchable user picker first.
  cache status shows picker-cache freshness.
  cache refresh warms the user and group picker caches for fast first use.

Generated TSV filenames:
  user mode:  <user-upn-slug>.<direct|transitive>.groups.tsv
  group mode: <group-name-slug>_<first-8-of-group-id>.<direct|transitive>.users.tsv
  reports:    <user-upn-slug>.<direct|transitive>.reports.tsv

Notes:
  - Defaults to --transitive, so nested group membership is included.
  - --direct returns only objects assigned directly to the user/group.
  - --transitive returns direct assignments plus nested membership.
  - For reports, --direct returns only direct reports and --transitive walks
    every reporting level below the starting user.
  - For users, output is the groups the user belongs to.
  - For groups, output is the user members of the group.
  - For compare-users, output is shared groups and groups only each user has.
  - For compare-groups, output is shared users and users only each group has.
  - For reports, output includes the starting user at LEVEL 0.
  - Defaults to human-readable output on stdout.
  - Human-readable output shows full email addresses and full object ids.
  - Pass --full to show uncapped names in the human-readable output.
  - TSV output always includes full exact values.
  - --interactive/--fzf requires fzf and cannot be combined with --tsv.
  - users/search, groups/search-groups, dept, and picker-based reports require fzf.
  - users/search, groups/search-groups, dept, and picker-based reports cache picker
    lists for 24 hours in the user cache directory.
  - Pass --refresh-cache to rebuild the search cache, or --no-cache to bypass it.
  - Use 'entra cache refresh' from launchd or cron to warm user/group search caches.
  - Set ENTRA_MEMBERSHIP_CACHE_TTL_SECONDS to change the search cache TTL.
  - Color defaults to auto. Set NO_COLOR=1 or pass --no-color to disable it.
  - If a group display name matches multiple groups, the app prints the matches
    and exits. Re-run with the group id to avoid exporting the wrong group.
  - Requires Azure CLI auth to already be configured. Search pickers require fzf.
"""
