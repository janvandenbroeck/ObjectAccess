# Object Access for Salesforce

Sometimes it's useful to have an easy overview of the number of custom objects a user has access to within the Salesforce Platform.

For example, it could be used as a self-audit tool when certain contractual license limits are not enforced by the platform.

This Lightning Component provides a lightweight, read-only, easy-to-use report of that number of custom objects by user.

## Mode of operation

This component summarizes the count of objects where the user has Read or higher permissions, across the profile and all permission sets assigned to the user.

This Object Access component only takes non-namespaced custom objects into account.

Included in count:
eg. Appliance__c,

No included:
eg Account, Case, SBQQ__Rule__c

## License
Please see LICENSE.txt.
This is not an official or endorsed tool, and only serves as illustration of a potential approach.
