# Object Access for Salesforce

Sometimes it's useful to have an easy overview of the number of custom objects, and which standard objects a user has access to within the Salesforce Platform.

For example, it could be used as a self-audit tool when certain contractual license limitations are not enforced by the platform.

This Lightning Component provides a lightweight, read-only, easy-to-use report of those objects, by profile and user.

## Mode of operation

This component summarizes the count of custom objects where the user has Read or higher permissions, across the profile and all permission sets assigned to the user. Only non-namespaced custom objects are taken into account.

Included in the count of custom objects:
eg. Appliance__c,

Not included in the count of custom objects:
eg Account, Case, SBQQ__Rule__c, ...

In addition, the component provides an overview of access to a common set of standard objects, indicating whether the user has Read (R), Create (C), Edit (E), or Create/Edit (C/E) permissions.

## License
Please see LICENSE.txt.
This is not an official or endorsed tool, and only serves as illustration of a potential approach.
