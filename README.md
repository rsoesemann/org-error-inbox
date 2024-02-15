# Salesforce Org Error Inbox

The Org Error Inbox is a native Salesforce App that receives your orgs error emails. It organizes them, notifies you and helps you solve the underlying issues.

**Features:**

- **Custom Metadata** Tokenizer for flexible Email Parsing
- Notify **Slack** Channel when email is received
- [Explain errors and fixes using **OpenAI API** integration](https://youtu.be/dERb_22VSfI)

## TL;DR - Click for Video Demo!

[![](http://img.youtube.com/vi/m0m6TH8-mnM/hqdefault.jpg)](https://youtu.be/m0m6TH8-mnM "")

## How does it work?

Salesforce orgs send out unhandled errors to the main admin's email address. If you redirect such email to this apps email service, it will receive and parse them into a Custom Object OrgError__c. 

All this information is stored in a single Custom Object and can be easily used for reporting and sophisticated support workflows.

## How can I use and extend this?

The project was built as a flexible unnamespaced SFDX project. The repo contains all the scripts to automatically build dev scratch orgs and sample data to play with.

Feel free to fork the repo and extend it. We would love to get improvements as Pull Request from you. Or create issues when you find a problem but don't want to fix it on your own.
