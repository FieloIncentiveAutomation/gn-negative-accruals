# !/bin/bash
echo "Setting instance" &&
sf config set org-instance-url=https://CS81.salesforce.com;

echo "Setting session Id" &&
session_id='00D260000009Ikd!ARIAQApYu1.j5LwIti4pHtcejihgRk1lIuGwRQfjO11Hs9fqwHCX1yl03t7KwpzOY7jn6TWq5fR6E7XmsKOWoWis1sIXcjeT';

sf project deploy start \
    --metadata ApexClass \
    --metadata ApexTrigger \
    --test-level RunSpecifiedTests \
    --tests TestNegativeAccruals \
    --tests F_TestBonusBasedStatusBatchScheduler \
    --coverage-formatters text \
    --coverage-formatters text-summary \
    --concise \
    --dry-run \
    --results-dir .local/ \
    --target-org $session_id &&

echo "Unset instance" &&
sf config unset org-instance-url