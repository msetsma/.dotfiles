USER_DETAIL_FIELDS = [
    "id",
    "displayName",
    "userPrincipalName",
    "mail",
    "accountEnabled",
    "userType",
    "jobTitle",
    "department",
    "companyName",
    "officeLocation",
    "employeeId",
    "employeeType",
    "mobilePhone",
    "businessPhones",
    "mailNickname",
    "onPremisesUserPrincipalName",
    "onPremisesSamAccountName",
    "onPremisesSyncEnabled",
    "createdDateTime",
    "proxyAddresses",
]
USER_SEARCH_FIELDS = [
    "id",
    "displayName",
    "userPrincipalName",
    "mail",
    "accountEnabled",
    "userType",
    "jobTitle",
    "department",
    "companyName",
    "officeLocation",
]
USER_RESOLVE_FIELDS = ["id", "displayName", "userPrincipalName", "mail"]
GROUP_SEARCH_FIELDS = [
    "id",
    "displayName",
    "mail",
    "mailEnabled",
    "securityEnabled",
    "groupTypes",
    "createdDateTime",
]
GROUP_MEMBER_FIELDS = ["id", "displayName", "userPrincipalName", "mail", "accountEnabled"]
REPORT_USER_FIELDS = [
    "id",
    "displayName",
    "userPrincipalName",
    "mail",
    "accountEnabled",
    "userType",
    "jobTitle",
    "department",
    "companyName",
    "officeLocation",
    "employeeId",
    "employeeType",
    "createdDateTime",
]


def select_fields(fields: list[str]) -> str:
    return ",".join(fields)
