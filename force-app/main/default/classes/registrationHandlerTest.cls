/*****************************************************************
* @description: Tests the creation and update of a user
* @class: registrationHandler
* @author david.lewakis@mindsquare.de
* @data 04.07.2025
* *
* @modifiedBy  : Andrei Pivavarchyk (mindsquare GmbH)
* @modifiedDate: 10.09.2025
* @modification: Extended tests for meeting sharing
*****************************************************************/

@IsTest
private class registrationHandlerTest {
    private static final String MANDANT_ID = '4250161800001'; // Eugen König
    private static final String FIRST_NAME = 'FirstName';
    private static final String LAST_NAME = 'LastName';
    private static final String E_MAIL = 'testuser@example.com-hbgtest12';
    private static final String USER_NAME = 'testuser@example.com-hbgtest12.hbg';
    private static final String KEYCLOAK_ID = '8b70b5d2-e1ab-42a3-99ef-a33596d70eff';

    private static List<Account> testAccounts;
    static List<Meeting__c> acc0Meetings;
    static List<Meeting__c> acc1Meetings;
    static {
        Account acc1 = new Account(Name = 'Account 0', ManufacturerId__c = 'ID0', BillingStreet = 'Teststraße 1', BillingPostalCode = '12345', BillingCity = 'Teststadt', BillingCountry = 'Deutschland');
        Account acc2 = new Account(Name = 'Account 1', ManufacturerId__c = 'ID1', BillingStreet = 'Teststraße 1', BillingPostalCode = '12345', BillingCity = 'Teststadt', BillingCountry = 'Deutschland');
        
        testAccounts = new List<Account>{acc1, acc2};

        insert testAccounts;

        acc0Meetings = new List<Meeting__c>{
                new Meeting__c(
                        StartDateTime__c = Datetime.now(),
                        EndDateTime__c   = Datetime.now().addDays(3),
                        Type__c = 'Allgemein',
                        Subject__c = 'Test A0-1',
                        Company__c = acc1.Id
                ),
                new Meeting__c(
                        StartDateTime__c = Datetime.now(),
                        EndDateTime__c   = Datetime.now().addDays(3),
                        Type__c = 'Allgemein',
                        Subject__c = 'Test A0-2',
                        Company__c = acc1.Id
                )
        };

        acc1Meetings = new List<Meeting__c>{
                new Meeting__c(
                        StartDateTime__c = Datetime.now(),
                        EndDateTime__c   = Datetime.now().addDays(3),
                        Type__c = 'Allgemein',
                        Subject__c = 'Test A1-1',
                        Company__c = acc2.Id
                ),
                new Meeting__c(
                        StartDateTime__c = Datetime.now(),
                        EndDateTime__c   = Datetime.now().addDays(3),
                        Type__c = 'Allgemein',
                        Subject__c = 'Test A1-2',
                        Company__c = acc2.Id
                )
        };
        insert acc0Meetings;
        insert acc1Meetings;
    }

    @IsTest
    static void testCreateUserBasicAttributes() {
        Map<String, String> attributeMap = new Map<String, String>{
            'sub' => KEYCLOAK_ID,
            'mandantID' => MANDANT_ID,
            'username' => USER_NAME,
            'email' => E_MAIL
        };

        Test.startTest();
        // Create Auth.UserData using correct constructor
        Auth.UserData data = createAuthData(attributeMap);
        data.idTokenJSONString = '';

        // Instantiate handler and create user
        registrationHandler handler = new registrationHandler();
        User user = handler.createUser(null, data);

        Test.stopTest();

        // Check user attributes
        user = [SELECT Alias, KeyCloackId__c, MandantId__c, Email, Username, ProfileId FROM User WHERE Id = :user.Id];
        
        Assert.areEqual('FLastNam', user.Alias, 'Alias is not as expected'); // trimmed
        Assert.areEqual(KEYCLOAK_ID, user.KeyCloackId__c, 'KeyCloakId __c is not as expected');
        Assert.areEqual(MANDANT_ID, user.MandantID__c, 'mandantID__c is not as expected');
        Assert.areEqual(E_MAIL, user.Email, 'Email is not as expected');
        Assert.areEqual(USER_NAME, user.Username, 'Username is not as expected');

        Profile profile = [SELECT Id FROM Profile WHERE Name = :registrationHandler.PROFILE_NAME LIMIT 1];
        
        Assert.areEqual(profile.id, user.ProfileId, 'Not the Profile as expected');

        Set<String> permissionSetNames = new Set<String>{registrationHandler.STANDARD_PERMISSION_SET,registrationHandler.DOCUMENTS_STANDARD_USER_PERMISSION_SET,registrationHandler.MEETING_PERMISSION_SET};
        List<PermissionSet> standardPs = [SELECT Id FROM PermissionSet WHERE Name IN: permissionSetNames];

        if (standardPs.isEmpty()) {
            return;
        }
        
        List<PermissionSetAssignment> assignments = [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :user.Id AND PermissionSetId IN: standardPs];
        List<UserPackageLicense> userPackageLicenses = [SELECT PackageLicenseId FROM UserPackageLicense WHERE UserId = :user.Id AND PackageLicense.NamespacePrefix =:registrationHandler.PACKAGE_LICENSE_DOCUMENTS_NAME_SPACE
        ];
        Assert.areEqual(3, assignments.size(), 'Permission set should be assigned to user.');
        Assert.areEqual(1, userPackageLicenses.size(), 'Permission set License should be assigned to user.');
    }

    @IsTest
    static void testCreateUserWithManufactureAccess() {
        String kamManufacturer = '[{"ManufacturerName": "Account 0","ManufacturerID": "ID0"},{"ManufacturerName": "Viega","ManufacturerID": "VI"}]';

        Map<String, String> attributeMap = new Map<String, String>{
            'sub' => KEYCLOAK_ID,
            'mandantID' => MANDANT_ID,
            'username' => USER_NAME,
            'email' => E_MAIL
        };
            
        Map<String, Object> tokenPayload = new Map<String, Object>{
    		'KAM-Manufacturer' => JSON.deserializeUntyped(kamManufacturer)
		};

        // Create Auth.UserData using correct constructor
        Auth.UserData data = createAuthData(attributeMap);
        data.idTokenJSONString = JSON.serialize(tokenPayload);

        // Instantiate handler and create user
        registrationHandler handler = new registrationHandler();
        User user = handler.createUser(null, data);

        // Verify AccountShare created only for acc1
        List<AccountShare> shares = [SELECT AccountId FROM AccountShare WHERE UserOrGroupId = :user.Id];

        Assert.areEqual(1, shares.size(), 'Number of shared Accounts is not matching');
        Assert.areEqual(testAccounts[0].Id, shares[0].AccountId, 'Id of shared Account is not matching');
    }

    @IsTest
    static void testCreateUserWithAllAccessRole() {
        Map<String, String> attributeMap = new Map<String, String>{
            'username' => USER_NAME,
            'email' => E_MAIL
        };

        Auth.UserData data = createAuthData(attributeMap);
        data.idTokenJSONString = '["' + registrationHandler.ALL_ACCESS_ROLE + '"]';

        registrationHandler handler = new registrationHandler();
        
        Test.startTest();
        User user = handler.createUser(null, data);
        Test.stopTest();
        Set<String> expectedPsNames = new Set<String>{
                registrationHandler.DOCUMENTS_STANDARD_USER_PERMISSION_SET,
                registrationHandler.MEETING_PERMISSION_SET,
                registrationHandler.STANDARD_PERMISSION_SET,
                registrationHandler.VIEW_ALL_PERMISSION_SET,
                registrationHandler.VIEW_ALL_MEETINGS_PERMISSION_SET
        };
        List<PermissionSet> viewAllPs = [SELECT Id FROM PermissionSet WHERE Name IN: expectedPsNames];

        if (viewAllPs.isEmpty()) {
            return;
        }

        List<PermissionSetAssignment> permissionSetAssignment = [
                SELECT Id, PermissionSetId, PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE AssigneeId = :user.Id
                AND PermissionSetId IN :viewAllPs
        ];

        Set<String> assignedPermissionSetNames = new Set<String>();
        for (PermissionSetAssignment assignment : permissionSetAssignment) {
            assignedPermissionSetNames.add(assignment.PermissionSet.Name);
        }
        for (String name : expectedPsNames) {
            System.assert(
                    assignedPermissionSetNames.contains(name),
                    'Expected Permission Set not assigned: ' + name
            );
        }
    }

    @IsTest
    static void testCreateUserWithSFSparte() {
        String sfSparte = '[{"Hersteller": [{"ManufacturerName": "Account 0","ManufacturerID": "ID0"}, {"ManufacturerName": "Keuco","ManufacturerID": "KE"}],"SparteID": "SAN","Spartename": "Sanitär"}]';

        Map<String, String> attributeMap = new Map<String, String>{
                'sub' => KEYCLOAK_ID,
                'mandantID' => MANDANT_ID,
                'username' => USER_NAME,
                'email' => E_MAIL
        };

        Map<String, Object> tokenPayload = new Map<String, Object>{
                'SF-Sparte' => JSON.deserializeUntyped(sfSparte)
        };

        Auth.UserData data = createAuthData(attributeMap);
        data.idTokenJSONString = JSON.serialize(tokenPayload);

        registrationHandler handler = new registrationHandler();
        User user = handler.createUser(null, data);

        List<AccountShare> shares = [SELECT AccountId FROM AccountShare WHERE UserOrGroupId = :user.Id];

        Assert.areEqual(1, shares.size(), 'Number of shared Accounts is not matching');
        Assert.areEqual(testAccounts[0].Id, shares[0].AccountId, 'Id of shared Account is not matching');

        Set<Id> sharedMeetings = new Set<Id>();

        List<Meeting__Share> meetingShareRecords = [
                SELECT ParentId, UserOrGroupId, RowCause
                FROM Meeting__Share
                WHERE UserOrGroupId = :user.Id
        ];

        for (Meeting__Share shareRecord : meetingShareRecords) {
            sharedMeetings.add(shareRecord.ParentId);
        }
        system.debug('sharedMeetings:'+sharedMeetings);
        //Meetings related to the account with ManufacturerID": "ID0"
        for (Meeting__c meeting : acc0Meetings) {
            Assert.isTrue(sharedMeetings.contains(meeting.Id));
        }
        //Meetings not related to the account with ManufacturerID": "ID0"
        for (Meeting__c meeting : acc1Meetings) {
            Assert.isTrue(!sharedMeetings.contains(meeting.Id));
        }
    }

    @IsTest
    static void testDeleteAccountAccess() {
        String kamManufacturer = '[{"ManufacturerName": "Account 0","ManufacturerID": "ID0"},{"ManufacturerName": "Viega","ManufacturerID": "VI"}]';

        Map<String, String> attributeMap = new Map<String, String>{
            'sub' => KEYCLOAK_ID,
            'mandantID' => MANDANT_ID,
            'username' => USER_NAME,
            'email' => E_MAIL
        };
            
        Map<String, Object> tokenPayload = new Map<String, Object>{
    		'KAM-Manufacturer' => JSON.deserializeUntyped(kamManufacturer)
		};
            
        Auth.UserData data = createAuthData(attributeMap);
        data.idTokenJSONString = JSON.serialize(tokenPayload);

        // Instantiate handler and create user
        registrationHandler handler = new registrationHandler();
        User user = handler.createUser(null, data);

        // Verify AccountShare and MeetingShare created only for acc1
        List<AccountShare> accountShareRecords = [SELECT AccountId FROM AccountShare WHERE UserOrGroupId = :user.Id];
        List<Meeting__Share> meetingShareRecordsBefore = [SELECT Id  FROM Meeting__Share  WHERE UserOrGroupId = :user.Id AND ParentId IN :acc0Meetings];


        Assert.areEqual(1, accountShareRecords.size(), 'Number of shared Accounts is not matching');
        Assert.areEqual(acc0Meetings.size(), meetingShareRecordsBefore.size(), 'Number of shared Meetings is not matching');
        Assert.areEqual(testAccounts[0].Id, accountShareRecords[0].AccountId, 'Id of shared Account is not matching');

        String newkKamManufacturer = '[{"ManufacturerName": "Viega","ManufacturerID": "VI"}]';
        attributeMap = new Map<String, String>{
            'sub' => KEYCLOAK_ID,
            'mandantID' => MANDANT_ID,
            'username' => USER_NAME,
            'email' => E_MAIL
        };
        
        tokenPayload = new Map<String, Object>{
    		'KAM-Manufacturer' => JSON.deserializeUntyped(newkKamManufacturer)
		};

        data = createAuthData(attributeMap);
        data.idTokenJSONString = JSON.serialize(tokenPayload);

        handler.updateUser(user.Id, null, data);

        // Account and Meetings should no longer be shared
        accountShareRecords = [SELECT AccountId FROM AccountShare WHERE UserOrGroupId = :user.Id];
        List<Meeting__Share> meetingShareRecordsAfter = [SELECT Id  FROM Meeting__Share  WHERE UserOrGroupId = :user.Id AND ParentId IN :acc0Meetings];

        Assert.areEqual(0, accountShareRecords.size(), 'Number of shared Accounts is not matching, should no longer be shared');
        Assert.areEqual(0, meetingShareRecordsAfter.size(), 'Number of shared Meetings is not matching, should no longer be shared');
    }

    @IsTest
    static void testSetBasicAttributes_ThrowsExceptions() {
        registrationHandler handler = new registrationHandler();

        Map<String, String> attributeMap = new Map<String, String>{
            'sub' => KEYCLOAK_ID,
            'mandantID' => MANDANT_ID
        };

        Auth.UserData data = createAuthData(attributeMap);

        try {
            data = createAuthData(attributeMap);
            handler.createUser(null, data);

            Assert.fail();
        } catch (IllegalArgumentException e) {
            Assert.areEqual('Username is missing!', e.getMessage(), 'Expected exception for missing Username');
        }

        try {
            attributeMap.put('username', USER_NAME);
            data = createAuthData(attributeMap);
            handler.createUser(null, data);

            Assert.fail();
        } catch (IllegalArgumentException e) {
            Assert.areEqual('E-Mail is missing!', e.getMessage(), 'Expected exception for missing email');
        }

        try {
            attributeMap.put('email', E_MAIL);
            data = createAuthData(attributeMap);
            data.lastName = null;
            handler.createUser(null, data);
            
            Assert.fail();
        } catch (IllegalArgumentException e) {
            Assert.areEqual('Last name is missing!', e.getMessage(), 'Expected exception for missing last name');
        }
    }

    private static Auth.UserData createAuthData(Map<String, String> attributeMap) {
        return new Auth.UserData(
            null, // identifier
            FIRST_NAME, // firstName
            LAST_NAME, //lastName
            FIRST_NAME + ' ' + LAST_NAME, // fullName
            E_MAIL, // email
            null, // link
            USER_NAME, // userName
            null, // local
            null, // provider
            null, // siteLoginUrl
            attributeMap // attributeMap
        );
    }

}