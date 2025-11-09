#!/bin/bash

# Check CloudTrail logs for OIDC errors

echo "🔍 Checking CloudTrail logs for OIDC errors..."
echo ""

# Get recent AssumeRoleWithWebIdentity events
echo "Recent AssumeRoleWithWebIdentity events:"
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity \
  --max-results 5 \
  --query 'Events[*].{Time:EventTime,Error:CloudTrailEvent}' \
  --output json 2>/dev/null | jq -r '.[] | "Time: \(.Time)\nError: \(.Error | fromjson | .errorMessage // .responseElements // .)"' 2>/dev/null || echo "No events found or error accessing CloudTrail"

echo ""
echo "To see more details:"
echo "1. Go to AWS CloudTrail Console"
echo "2. Click 'Event history'"
echo "3. Filter by: Event name = 'AssumeRoleWithWebIdentity'"
echo "4. Look for error events in the last hour"
echo ""

