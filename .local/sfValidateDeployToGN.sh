# !/bin/bash
echo "Setting instance" &&
sf config set org-instance-url=https://CS81.salesforce.com;

echo "Setting session Id" &&
session_id='00D260000009Ikd!ARIAQHPkRIOtVcuooE9Yk4VxtqPZu0RLNCRI89cke89zZmc7VVoQVwkiZOwNm5o.fXSvnDr5AFzRTWoCpFt_4uhixKqW_D0l';

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