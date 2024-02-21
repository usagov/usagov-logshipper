<!--- Provide a general summary of your changes in the title above -->
## Jira Task
<!--- Provide a link to the Jira ticket -->
https://cm-jira.usa.gov/browse/USAGOV-

## Description
<!--- Summarize the changes made in this pull request, not what it's for. -->

## Type of Changes
<!--- Put an `x` in all the boxes that apply. -->
- [ ] New Feature
- [ ] Bugfix
- [ ] Other

## Testing Instructions
<!-- This instructions are different from “testing instructions” in Jira – those are typically for Content/UX stakeholders -->
<!-- Not “see Jira” – if they are really the same, copy and paste. -->



## Security Review
<!-- Checkboxes to indicate need for review -->

- [ ] Adds/updates software (including a library or Drupal module)
- [ ] Communication with external service
- [ ] Changes permissions or workflow
- [ ] Requires SSPP updates


## Reviewer Reminders
- Reviewed code changes
- Reviewed functionality
- Security review complete or not required

## Post PR Approval Instructions
Follow these steps as soon as you merge the new changes. 

1. Go to the [USAGov Circle CI project](https://app.circleci.com/pipelines/github/usagov/usagov-logshipper).
2. Find the commit of this pull request.
3. Deploy the log-shipper. Watch the logs and make sure all went well.
4. Update the Jira ticket by changing the ticket status to `Done` and add a comment. 
