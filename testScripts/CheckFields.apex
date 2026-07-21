/**
 * Check what fields actually exist in the org
 */

System.debug('=== Checking Pull_Request__c Fields ===');
Schema.DescribeSObjectResult describe = Schema.SObjectType.Pull_Request__c;
Map<String, Schema.SObjectField> fields = describe.fields.getMap();

System.debug('Total fields on Pull_Request__c: ' + fields.size());

// Check for specific fields we need
List<String> requiredFields = new List<String>{
    'PR_Number__c',
    'Title__c',
    'State__c',
    'External_Id__c',
    'Author__c',
    'Repository__c'
};

System.debug('\nChecking required fields:');
for (String fieldName : requiredFields) {
    if (fields.containsKey(fieldName.toLowerCase())) {
        System.debug('  ✅ ' + fieldName + ' EXISTS');
    } else {
        System.debug('  ❌ ' + fieldName + ' MISSING');
    }
}

System.debug('\n=== Checking Repository__c Fields ===');
Schema.DescribeSObjectResult repoDescribe = Schema.SObjectType.Repository__c;
Map<String, Schema.SObjectField> repoFields = repoDescribe.fields.getMap();

System.debug('Total fields on Repository__c: ' + repoFields.size());

List<String> repoRequiredFields = new List<String>{
    'External_Id__c',
    'Last_Synced__c',
    'Default_Branch__c',
    'Description__c'
};

System.debug('\nChecking required fields:');
for (String fieldName : repoRequiredFields) {
    if (repoFields.containsKey(fieldName.toLowerCase())) {
        System.debug('  ✅ ' + fieldName + ' EXISTS');
    } else {
        System.debug('  ❌ ' + fieldName + ' MISSING');
    }
}

System.debug('\n=== Checking Classes ===');
try {
    Type syncService = Type.forName('RepositorySyncService');
    if (syncService != null) {
        System.debug('  ✅ RepositorySyncService EXISTS');
    }
} catch (Exception e) {
    System.debug('  ❌ RepositorySyncService MISSING');
}

try {
    Type prSyncService = Type.forName('PullRequestSyncService');
    if (prSyncService != null) {
        System.debug('  ✅ PullRequestSyncService EXISTS');
    }
} catch (Exception e) {
    System.debug('  ❌ PullRequestSyncService MISSING');
}

System.debug('\n=== Data Counts ===');
System.debug('Repositories: ' + [SELECT COUNT() FROM Repository__c]);
System.debug('Pull Requests: ' + [SELECT COUNT() FROM Pull_Request__c]);
