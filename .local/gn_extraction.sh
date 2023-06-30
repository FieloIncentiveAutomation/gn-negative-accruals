# !/bin/bash

echo "Setting instance" &&
sf config set org-instance-url=https://EU47.salesforce.com;

echo "Setting session Id" &&
session_id='00D200000006Wrs!ARYAQKHT2X9EWruF_YdWTOPHvITuwJEbKr3HHHcm1hfDplSwkGmOygPv_rDDginVjn5qmgH6hk974g1mrWX6HDQB0JY74hjS';

echo "Getting Classes" &&
sf project retrieve start \
    --metadata ApexClass:F_BonusBasedStatusBatchScheduler \
    --metadata ApexClass:F_TestBonusBasedStatusBatchScheduler \
    --metadata ApexClass:F_SObjectForTest \
    --metadata CustomField:FieloPLT__Transaction__c.FlexpointExpirationDate__c \
    --metadata CustomField:FieloPLT__Transaction__c.Flexpoint__c \
    --metadata CustomField:FieloPLT__Transaction__c.F_Online_Transaction_Type__c \
    --metadata CustomField:FieloPLT__Level__c.F_threshold__c \
    --metadata CustomField:FieloPLT__Member__c.Flexpoint__c \
    --metadata CustomFIeld:FieloPLT__Member__c.F_OptOut__c \
    --metadata CustomFIeld:FieloPLT__Member__c.F_LevelOverri_deEndDt__c \
    --target-org $session_id &&

echo "Unset instance" &&
sf config unset org-instance-url