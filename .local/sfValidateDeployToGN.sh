# !/bin/bash
echo "Setting instance" &&
sf config set org-instance-url=https://CS81.salesforce.com;

echo "Setting session Id" &&
session_id='00D260000009Ikd!ARIAQMCiAuiHPxv4zX9U7RB.cxkmiuiQNwAOL0MH64GkNxdqJtau_4XPuLFL0ggNtbLqFFhB7syYy79sftTgp7po9NukSpIN';

sf project deploy start \
    --metadata ApexClass \
    --metadata ApexTrigger \
    --metadata PermissionSet \
    --test-level RunSpecifiedTests \
    --tests TestNegativeAccruals \
    --tests F_TestBonusBasedStatusBatchScheduler \
    --coverage-formatters text \
    --coverage-formatters text-summary \
    --concise \
    --results-dir .local/ \
    --target-org $session_id &&

echo "Unset instance" &&
sf config unset org-instance-url