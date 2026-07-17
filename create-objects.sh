#!/bin/bash

# Script to create all custom object fields efficiently
BASE_DIR="$HOME/Documents/DevOpsCompass/force-app/main/default/objects"

# Create Contributor fields
mkdir -p "$BASE_DIR/Contributor__c/fields"
cd "$BASE_DIR/Contributor__c/fields"

cat > External_Id__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>External_Id__c</fullName>
    <label>External ID</label>
    <description>GitHub User ID</description>
    <type>Text</type>
    <length>100</length>
    <externalId>true</externalId>
    <unique>true</unique>
</CustomField>
EOF

cat > GitHub_Username__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>GitHub_Username__c</fullName>
    <label>GitHub Username</label>
    <type>Text</type>
    <length>80</length>
</CustomField>
EOF

cat > Email__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Email__c</fullName>
    <label>Email</label>
    <type>Email</type>
</CustomField>
EOF

cat > Active__c.field-meta.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Active__c</fullName>
    <label>Active</label>
    <type>Checkbox</type>
    <defaultValue>true</defaultValue>
</CustomField>
EOF

echo "Contributor fields created"
