#!/bin/bash

# Script to find the exact repository name from CloudTrail logs

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🔍 Finding Exact Repository Name from CloudTrail${NC}"
echo ""

echo "Checking CloudTrail logs for the actual repository name..."
echo ""

# Get the most recent successful AssumeRoleWithWebIdentity event
RECENT_EVENT=$(aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRoleWithWebIdentity \
  --max-results 1 \
  --query 'Events[0].CloudTrailEvent' \
  --output text 2>/dev/null)

if [ -n "$RECENT_EVENT" ] && [ "$RECENT_EVENT" != "None" ]; then
    echo -e "${GREEN}✅ Found recent event!${NC}"
    echo ""
    echo "Extracting repository name from the event..."
    echo ""
    
    # Parse the event to find the subject (repo name)
    REPO_NAME=$(echo "$RECENT_EVENT" | jq -r '.requestParameters.webIdentityToken // empty' 2>/dev/null | base64 -d 2>/dev/null | jq -r '.sub // empty' 2>/dev/null)
    
    if [ -n "$REPO_NAME" ]; then
        echo -e "${GREEN}✅ Repository name found:${NC}"
        echo "   $REPO_NAME"
        echo ""
        echo "Use this exact value in your trust policy:"
        echo "   \"token.actions.githubusercontent.com:sub\": \"$REPO_NAME\""
        echo ""
    else
        echo -e "${YELLOW}⚠️  Could not extract repository name from event${NC}"
        echo ""
        echo "Alternative method: Check the event details manually"
        echo ""
        echo "Full event details:"
        echo "$RECENT_EVENT" | jq '.' 2>/dev/null || echo "$RECENT_EVENT"
    fi
else
    echo -e "${YELLOW}⚠️  No recent events found${NC}"
    echo ""
    echo "Alternative: Check the GitHub Actions workflow context"
    echo ""
    echo "In your GitHub Actions workflow, you can add this step to see the exact repo:"
    echo ""
    cat <<'EOF'
- name: Debug Repository Context
  run: |
    echo "Repository: ${{ github.repository }}"
    echo "Repository owner: ${{ github.repository_owner }}"
    echo "Repository name: ${{ github.event.repository.name }}"
    echo "Full context: repo:${{ github.repository }}:*"
EOF
fi

echo ""
echo -e "${BLUE}📋 Manual Check:${NC}"
echo ""
echo "You can also check the repository name by:"
echo "1. Going to your GitHub repository"
echo "2. Check the URL: https://github.com/OWNER/REPO"
echo "3. The format should be: repo:OWNER/REPO:*"
echo ""
echo "Make sure:"
echo "  - No extra spaces"
echo "  - Case-sensitive (exact match)"
echo "  - Includes :* at the end"
echo ""

