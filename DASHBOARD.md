## A Note About Dashboard Configuration

We recommend that you manually set a Specified User for the dashboard after deployment.  The out-of-the-box dashboard may appear differently to different users depending on their permissions and sharing.

**Background**: In order to allow this unlocked package to be manually installed using SFDX-based tools (such as the "Deploy to Salesforce" button on the main README), it was neccessary to remove any hard-coded references to specific users who may not be present in your Salesforce org or sandbox.  As a result, the "View Dashboard As" setting is configured to "The Dashboard Viewer", as opposed to a specified user with full visibility into all records.

To solve this issue, after deployment:

1) Ensure your own user has the Permission Set "Org Error Inbox Admin" and is a member of the Public Group "Org Error Inbox Admin"
2) Navigate to the Dashboard App, and select "edit" for the "Org Error Inbox" dashboard
3) Click the "Settings" gear icon in the upper-right of the dashboard editor, and you will find the setting "View Dashboard As" where you can select "Me", "Other User", or "The Dashboard Viewer" (the latter being the deployment default for this dashboard).
4) Typically, it is recommended to select "Other User", and select a service account or integration user with full visibility into all OrgError__c records.  This will ensure the dashboard appears consistently to all users who view it in your org or sandbox.
