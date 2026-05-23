# Entra Tool Notes

This tool helps the team inspect people, groups, and organization structure so
we can design and validate access rules. It should make it easy to answer:

- Who is in this group?
- What groups is this person in?
- Why does this person have access?
- Which groups look like baseline access for a team?
- Which people are exceptions compared with their peers?

## Useful Additions

### Compare users

Show shared and different group membership for two users.

```sh
entra compare-users alice@example.com bob@example.com
```

Useful output:

- groups both users share
- groups only the first user has
- groups only the second user has
- likely access differences to review

### Compare groups

Show overlap and differences between two groups.

```sh
entra compare-groups "Group A" "Group B"
```

Useful for spotting duplicate groups, drift, and whether one group can replace
another.

### Explain membership

Show why a user is in a group, including nested group paths.

```sh
entra why-user-in-group user@example.com "Some Group"
```

Example output shape:

```text
User -> Team Group -> Department Group -> Access Group
```

### Group audit

Summarize potential hygiene issues for a group.

```sh
entra group "Some Group" --audit
```

Useful checks:

- disabled users
- users with no title
- external or guest users
- nested groups
- group owners
- empty groups
- groups with no owners
- mail-enabled, security, and Microsoft 365 group type details

### Org subtree group summary

Summarize common groups across everyone in a report tree.

```sh
entra reports manager@example.com --groups-summary
```

Example output shape:

```text
42/50  Some Base Access Group
39/50  Department App Users
12/50  Exception Group
```

This helps identify baseline access patterns and outliers.

### Exception detection

Find people whose group membership differs from peers in the same org tree.

```sh
entra reports manager@example.com --exceptions
```

Useful peer groupings:

- same manager
- same title
- same department
- same title and department

### JSON output

Add machine-readable output for automation.

```sh
entra reports manager@example.com --json
entra group "Group Name" --json
```

TSV is useful for spreadsheets; JSON would be better for scripts and follow-on
analysis.

### Interactive drill-down

In picker flows, make it easy to select a person or group and jump into related
views:

- user details
- user groups
- group users
- group owners
- membership explanation

## Suggested Priority

1. `compare-users`
2. `why-user-in-group`
3. `reports --groups-summary`
4. `group --audit`
5. `reports --exceptions`
