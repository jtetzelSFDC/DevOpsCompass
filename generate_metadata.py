#!/usr/bin/env python3
"""
Script to generate all Salesforce custom object metadata for DevOps Compass
"""
import os
from pathlib import Path

BASE_DIR = Path.home() / "Documents" / "DevOpsCompass" / "force-app" / "main" / "default" / "objects"

def create_field(obj_dir, field_name, field_config):
    """Create a custom field metadata file"""
    fields_dir = obj_dir / "fields"
    fields_dir.mkdir(exist_ok=True)

    field_file = fields_dir / f"{field_name}.field-meta.xml"

    xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>{field_name}</fullName>
    <label>{field_config['label']}</label>"""

    if 'description' in field_config:
        xml += f"\n    <description>{field_config['description']}</description>"

    xml += f"\n    <type>{field_config['type']}</type>"

    if field_config['type'] == 'Text':
        xml += f"\n    <length>{field_config.get('length', 255)}</length>"
    elif field_config['type'] == 'LongTextArea':
        xml += f"\n    <length>{field_config.get('length', 32768)}</length>"
        xml += f"\n    <visibleLines>{field_config.get('visibleLines', 3)}</visibleLines>"
    elif field_config['type'] == 'Number':
        xml += f"\n    <precision>{field_config.get('precision', 18)}</precision>"
        xml += f"\n    <scale>{field_config.get('scale', 0)}</scale>"
    elif field_config['type'] == 'Checkbox':
        xml += f"\n    <defaultValue>{str(field_config.get('defaultValue', False)).lower()}</defaultValue>"
    elif field_config['type'] == 'Picklist':
        xml += "\n    <valueSet>\n        <valueSetDefinition>\n            <sorted>false</sorted>"
        for value in field_config['values']:
            is_default = value.get('default', False)
            xml += f"\n            <value>\n                <fullName>{value['name']}</fullName>\n                <default>{str(is_default).lower()}</default>\n            </value>"
        xml += "\n        </valueSetDefinition>\n    </valueSet>"
    elif field_config['type'] == 'Lookup' or field_config['type'] == 'MasterDetail':
        xml += f"\n    <referenceTo>{field_config['referenceTo']}</referenceTo>"
        xml += "\n    <relationshipLabel>{}</relationshipLabel>".format(field_config.get('relationshipLabel', field_config['label'] + 's'))
        xml += "\n    <relationshipName>{}</relationshipName>".format(field_config.get('relationshipName', field_config['label'].replace(' ', '_')))

    if field_config.get('externalId'):
        xml += "\n    <externalId>true</externalId>"
    if field_config.get('unique'):
        xml += "\n    <unique>true</unique>"
    if field_config.get('required') and field_config['type'] not in ['Checkbox']:
        xml += "\n    <required>true</required>"

    xml += "\n</CustomField>\n"

    field_file.write_text(xml)

# Pull Request Object
pr_fields = {
    'PR_Number__c': {'label': 'PR Number', 'type': 'Number', 'precision': 10, 'scale': 0},
    'External_Id__c': {'label': 'External ID', 'type': 'Text', 'length': 100, 'externalId': True, 'unique': True},
    'Repository__c': {'label': 'Repository', 'type': 'Lookup', 'referenceTo': 'Repository__c', 'relationshipName': 'Pull_Requests'},
    'Title__c': {'label': 'Title', 'type': 'Text', 'length': 255},
    'Author__c': {'label': 'Author', 'type': 'Text', 'length': 80},
    'State__c': {'label': 'State', 'type': 'Picklist', 'values': [
        {'name': 'Open', 'default': False},
        {'name': 'Closed', 'default': False},
        {'name': 'Merged', 'default': False}
    ]},
    'Source_Branch__c': {'label': 'Source Branch', 'type': 'Text', 'length': 255},
    'Target_Branch__c': {'label': 'Target Branch', 'type': 'Text', 'length': 255},
    'Created_Date__c': {'label': 'Created Date', 'type': 'DateTime'},
    'Closed_Date__c': {'label': 'Closed Date', 'type': 'DateTime'},
    'Merged_Date__c': {'label': 'Merged Date', 'type': 'DateTime'},
    'Review_Count__c': {'label': 'Review Count', 'type': 'Number', 'precision': 5, 'scale': 0},
    'Commit_Count__c': {'label': 'Commit Count', 'type': 'Number', 'precision': 5, 'scale': 0},
    'Files_Changed__c': {'label': 'Files Changed', 'type': 'Number', 'precision': 5, 'scale': 0},
    'Lines_Added__c': {'label': 'Lines Added', 'type': 'Number', 'precision': 8, 'scale': 0},
    'Lines_Removed__c': {'label': 'Lines Removed', 'type': 'Number', 'precision': 8, 'scale': 0},
    'URL__c': {'label': 'URL', 'type': 'Url'}
}

pr_obj = BASE_DIR / "Pull_Request__c"
pr_obj.mkdir(exist_ok=True)
(pr_obj / "Pull_Request__c.object-meta.xml").write_text("""<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Pull Request</label>
    <pluralLabel>Pull Requests</pluralLabel>
    <nameField>
        <displayFormat>PR-{0000000}</displayFormat>
        <label>Pull Request Number</label>
        <type>AutoNumber</type>
    </nameField>
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>ReadWrite</sharingModel>
    <enableReports>true</enableReports>
    <enableSearch>true</enableSearch>
</CustomObject>
""")

for field_name, field_config in pr_fields.items():
    create_field(pr_obj, field_name, field_config)

print("Pull_Request__c created with all fields")

# Environment Object
env_fields = {
    'Org_ID__c': {'label': 'Org ID', 'type': 'Text', 'length': 18},
    'Environment_Type__c': {'label': 'Environment Type', 'type': 'Picklist', 'values': [
        {'name': 'DEV', 'default': False},
        {'name': 'QA', 'default': False},
        {'name': 'UAT', 'default': False},
        {'name': 'PROD', 'default': False}
    ]},
    'Sandbox_Type__c': {'label': 'Sandbox Type', 'type': 'Picklist', 'values': [
        {'name': 'Developer', 'default': False},
        {'name': 'Partial', 'default': False},
        {'name': 'Full', 'default': False}
    ]},
    'Active__c': {'label': 'Active', 'type': 'Checkbox', 'defaultValue': True},
    'Last_Refresh_Date__c': {'label': 'Last Refresh Date', 'type': 'Date'}
}

env_obj = BASE_DIR / "Environment__c"
env_obj.mkdir(exist_ok=True)
(env_obj / "Environment__c.object-meta.xml").write_text("""<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Environment</label>
    <pluralLabel>Environments</pluralLabel>
    <nameField>
        <label>Environment Name</label>
        <type>Text</type>
    </nameField>
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>ReadWrite</sharingModel>
    <enableReports>true</enableReports>
</CustomObject>
""")

for field_name, field_config in env_fields.items():
    create_field(env_obj, field_name, field_config)

print("Environment__c created")

# Deployment Object
deploy_fields = {
    'Pull_Request__c': {'label': 'Pull Request', 'type': 'Lookup', 'referenceTo': 'Pull_Request__c', 'relationshipName': 'Deployments'},
    'Environment__c': {'label': 'Environment', 'type': 'Lookup', 'referenceTo': 'Environment__c', 'relationshipName': 'Deployments'},
    'Status__c': {'label': 'Status', 'type': 'Picklist', 'values': [
        {'name': 'Pending', 'default': False},
        {'name': 'In Progress', 'default': False},
        {'name': 'Successful', 'default': False},
        {'name': 'Failed', 'default': False},
        {'name': 'Rolled Back', 'default': False}
    ]},
    'Deployment_Type__c': {'label': 'Deployment Type', 'type': 'Picklist', 'values': [
        {'name': 'Manual', 'default': False},
        {'name': 'GitHub Actions', 'default': False},
        {'name': 'Copado', 'default': False},
        {'name': 'Gearset', 'default': False}
    ]},
    'Triggered_By__c': {'label': 'Triggered By', 'type': 'Text', 'length': 255},
    'Start_Time__c': {'label': 'Start Time', 'type': 'DateTime'},
    'End_Time__c': {'label': 'End Time', 'type': 'DateTime'},
    'Notes__c': {'label': 'Notes', 'type': 'LongTextArea', 'length': 32768}
}

deploy_obj = BASE_DIR / "Deployment__c"
deploy_obj.mkdir(exist_ok=True)
(deploy_obj / "Deployment__c.object-meta.xml").write_text("""<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Deployment</label>
    <pluralLabel>Deployments</pluralLabel>
    <nameField>
        <displayFormat>DEP-{0000000}</displayFormat>
        <label>Deployment Number</label>
        <type>AutoNumber</type>
    </nameField>
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>ReadWrite</sharingModel>
    <enableReports>true</enableReports>
</CustomObject>
""")

for field_name, field_config in deploy_fields.items():
    create_field(deploy_obj, field_name, field_config)

print("Deployment__c created")

# Release Object
release_fields = {
    'Release_Number__c': {'label': 'Release Number', 'type': 'Text', 'length': 50},
    'Status__c': {'label': 'Status', 'type': 'Picklist', 'values': [
        {'name': 'Planning', 'default': False},
        {'name': 'QA', 'default': False},
        {'name': 'UAT', 'default': False},
        {'name': 'Ready', 'default': False},
        {'name': 'Deployed', 'default': False},
        {'name': 'Closed', 'default': False}
    ]},
    'Release_Type__c': {'label': 'Release Type', 'type': 'Picklist', 'values': [
        {'name': 'Major', 'default': False},
        {'name': 'Minor', 'default': False},
        {'name': 'Patch', 'default': False},
        {'name': 'Hotfix', 'default': False}
    ]},
    'Planned_Start_Date__c': {'label': 'Planned Start Date', 'type': 'Date'},
    'Planned_Release_Date__c': {'label': 'Planned Release Date', 'type': 'Date'},
    'Actual_Release_Date__c': {'label': 'Actual Release Date', 'type': 'Date'},
    'Target_Environment__c': {'label': 'Target Environment', 'type': 'Lookup', 'referenceTo': 'Environment__c', 'relationshipName': 'Releases'},
    'Release_Manager__c': {'label': 'Release Manager', 'type': 'Lookup', 'referenceTo': 'User', 'relationshipName': 'Managed_Releases'},
    'Notes__c': {'label': 'Release Notes', 'type': 'LongTextArea', 'length': 32768}
}

release_obj = BASE_DIR / "Release__c"
release_obj.mkdir(exist_ok=True)
(release_obj / "Release__c.object-meta.xml").write_text("""<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Release</label>
    <pluralLabel>Releases</pluralLabel>
    <nameField>
        <label>Release Name</label>
        <type>Text</type>
    </nameField>
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>ReadWrite</sharingModel>
    <enableReports>true</enableReports>
</CustomObject>
""")

for field_name, field_config in release_fields.items():
    create_field(release_obj, field_name, field_config)

print("Release__c created")

# Work Item Object
work_fields = {
    'External_Id__c': {'label': 'External ID', 'type': 'Text', 'length': 100, 'externalId': True},
    'Title__c': {'label': 'Title', 'type': 'Text', 'length': 255},
    'Description__c': {'label': 'Description', 'type': 'LongTextArea', 'length': 32768},
    'Work_Item_Type__c': {'label': 'Work Item Type', 'type': 'Picklist', 'values': [
        {'name': 'Story', 'default': False},
        {'name': 'Bug', 'default': False},
        {'name': 'Task', 'default': False},
        {'name': 'Epic', 'default': False},
        {'name': 'Spike', 'default': False}
    ]},
    'Status__c': {'label': 'Status', 'type': 'Picklist', 'values': [
        {'name': 'New', 'default': False},
        {'name': 'In Progress', 'default': False},
        {'name': 'Ready', 'default': False},
        {'name': 'Done', 'default': False}
    ]},
    'Priority__c': {'label': 'Priority', 'type': 'Picklist', 'values': [
        {'name': 'Low', 'default': False},
        {'name': 'Medium', 'default': True},
        {'name': 'High', 'default': False},
        {'name': 'Critical', 'default': False}
    ]},
    'Story_Points__c': {'label': 'Story Points', 'type': 'Number', 'precision': 3, 'scale': 0},
    'Sprint_Name__c': {'label': 'Sprint Name', 'type': 'Text', 'length': 100},
    'Repository__c': {'label': 'Repository', 'type': 'Lookup', 'referenceTo': 'Repository__c', 'relationshipName': 'Work_Items'},
    'Contributor__c': {'label': 'Contributor', 'type': 'Lookup', 'referenceTo': 'Contributor__c', 'relationshipName': 'Work_Items'},
    'Release__c': {'label': 'Release', 'type': 'Lookup', 'referenceTo': 'Release__c', 'relationshipName': 'Work_Items'},
    'Pull_Request__c': {'label': 'Pull Request', 'type': 'Lookup', 'referenceTo': 'Pull_Request__c', 'relationshipName': 'Work_Items'},
    'Created_Date__c': {'label': 'Created Date', 'type': 'Date'},
    'Closed_Date__c': {'label': 'Closed Date', 'type': 'Date'},
    'URL__c': {'label': 'URL', 'type': 'Url'}
}

work_obj = BASE_DIR / "Work_Item__c"
work_obj.mkdir(exist_ok=True)
(work_obj / "Work_Item__c.object-meta.xml").write_text("""<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Work Item</label>
    <pluralLabel>Work Items</pluralLabel>
    <nameField>
        <label>Work Item ID</label>
        <type>Text</type>
    </nameField>
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>ReadWrite</sharingModel>
    <enableReports>true</enableReports>
</CustomObject>
""")

for field_name, field_config in work_fields.items():
    create_field(work_obj, field_name, field_config)

print("Work_Item__c created")

# Sync Job Object
sync_fields = {
    'Job_Type__c': {'label': 'Job Type', 'type': 'Picklist', 'values': [
        {'name': 'GitHub Sync', 'default': True},
        {'name': 'Metrics Calculation', 'default': False}
    ]},
    'Start_Time__c': {'label': 'Start Time', 'type': 'DateTime'},
    'End_Time__c': {'label': 'End Time', 'type': 'DateTime'},
    'Status__c': {'label': 'Status', 'type': 'Picklist', 'values': [
        {'name': 'Running', 'default': False},
        {'name': 'Success', 'default': False},
        {'name': 'Failed', 'default': False}
    ]},
    'Records_Processed__c': {'label': 'Records Processed', 'type': 'Number', 'precision': 10, 'scale': 0},
    'Records_Inserted__c': {'label': 'Records Inserted', 'type': 'Number', 'precision': 10, 'scale': 0},
    'Records_Updated__c': {'label': 'Records Updated', 'type': 'Number', 'precision': 10, 'scale': 0},
    'API_Calls__c': {'label': 'API Calls', 'type': 'Number', 'precision': 6, 'scale': 0},
    'Error_Count__c': {'label': 'Error Count', 'type': 'Number', 'precision': 6, 'scale': 0},
    'Error_Log__c': {'label': 'Error Log', 'type': 'LongTextArea', 'length': 32768}
}

sync_obj = BASE_DIR / "Sync_Job__c"
sync_obj.mkdir(exist_ok=True)
(sync_obj / "Sync_Job__c.object-meta.xml").write_text("""<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Sync Job</label>
    <pluralLabel>Sync Jobs</pluralLabel>
    <nameField>
        <displayFormat>SYNC-{0000000}</displayFormat>
        <label>Sync Job Number</label>
        <type>AutoNumber</type>
    </nameField>
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>ReadWrite</sharingModel>
    <enableReports>true</enableReports>
</CustomObject>
""")

for field_name, field_config in sync_fields.items():
    create_field(sync_obj, field_name, field_config)

print("Sync_Job__c created")

# Metric Snapshot Object
metric_fields = {
    'Repository__c': {'label': 'Repository', 'type': 'Lookup', 'referenceTo': 'Repository__c', 'relationshipName': 'Metric_Snapshots'},
    'Snapshot_Date__c': {'label': 'Snapshot Date', 'type': 'Date'},
    'Deployment_Frequency__c': {'label': 'Deployment Frequency', 'type': 'Number', 'precision': 6, 'scale': 2},
    'Avg_PR_Cycle_Hours__c': {'label': 'Average PR Cycle (Hours)', 'type': 'Number', 'precision': 8, 'scale': 2},
    'Avg_Lead_Time_Hours__c': {'label': 'Average Lead Time (Hours)', 'type': 'Number', 'precision': 8, 'scale': 2},
    'Open_PRs__c': {'label': 'Open PRs', 'type': 'Number', 'precision': 6, 'scale': 0},
    'Closed_PRs__c': {'label': 'Closed PRs', 'type': 'Number', 'precision': 6, 'scale': 0},
    'Merged_PRs__c': {'label': 'Merged PRs', 'type': 'Number', 'precision': 6, 'scale': 0},
    'Active_Contributors__c': {'label': 'Active Contributors', 'type': 'Number', 'precision': 5, 'scale': 0}
}

metric_obj = BASE_DIR / "Metric_Snapshot__c"
metric_obj.mkdir(exist_ok=True)
(metric_obj / "Metric_Snapshot__c.object-meta.xml").write_text("""<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Metric Snapshot</label>
    <pluralLabel>Metric Snapshots</pluralLabel>
    <nameField>
        <displayFormat>MS-{0000000}</displayFormat>
        <label>Metric Snapshot Number</label>
        <type>AutoNumber</type>
    </nameField>
    <deploymentStatus>Deployed</deploymentStatus>
    <sharingModel>ReadWrite</sharingModel>
    <enableReports>true</enableReports>
</CustomObject>
""")

for field_name, field_config in metric_fields.items():
    create_field(metric_obj, field_name, field_config)

print("Metric_Snapshot__c created")

# Finish Contributor fields
contrib_fields = {
    'External_Id__c': {'label': 'External ID', 'type': 'Text', 'length': 100, 'externalId': True, 'unique': True},
    'GitHub_Username__c': {'label': 'GitHub Username', 'type': 'Text', 'length': 80},
    'Email__c': {'label': 'Email', 'type': 'Email'},
    'Organization__c': {'label': 'Organization', 'type': 'Text', 'length': 100},
    'Avatar_URL__c': {'label': 'Avatar URL', 'type': 'Url'},
    'Profile_URL__c': {'label': 'Profile URL', 'type': 'Url'},
    'Active__c': {'label': 'Active', 'type': 'Checkbox', 'defaultValue': True},
    'First_Sync_Date__c': {'label': 'First Sync Date', 'type': 'Date'},
    'Last_Activity_Date__c': {'label': 'Last Activity Date', 'type': 'Date'}
}

contrib_obj = BASE_DIR / "Contributor__c"
for field_name, field_config in contrib_fields.items():
    create_field(contrib_obj, field_name, field_config)

print("Contributor__c fields completed")
print("\nAll custom objects created successfully!")
