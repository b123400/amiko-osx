/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 21/06/2017.
 
 This file is part of AmiKo for OSX.
 
 AmiKo for OSX is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLPatientSheetController.h"
#import "MLPatientSheetController+smartCard.h"

#import "MLPatientDBAdapter.h"
#import "MLContacts.h"
#import "MLColors.h"
#import "MLUtilities.h"

@implementation MLPatientSheetController
{
    @private
    MLPatientDBAdapter *mPatientDb;
    MLPatient *mSelectedPatient;
    NSModalSession mModalSession;
    NSArray *mArrayOfPatients;
    NSMutableArray *mFilteredArrayOfPatients;
    NSString *mPatientUUID;
    BOOL mABContactsVisible;    // These are the contacts in the address book
    BOOL mSearchFiltered;
    BOOL mFemale;
}

- (id) init
{
    if (self = [super init]) {
        mArrayOfPatients = [[NSArray alloc] init];;
        mFilteredArrayOfPatients = [[NSMutableArray alloc] init];
        mSearchFiltered = FALSE;
        mPatientUUID = nil;
        
        // Open patient DB
        mPatientDb = [[MLPatientDBAdapter alloc] init];
        if (![mPatientDb openDatabase:@"patient_db"]) {
            NSLog(@"Could not open patient DB!");
            mPatientDb = nil;
        }
        
        mABContactsVisible = FALSE;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(controlTextDidChange:)
                                                     name:NSControlTextDidChangeNotification
                                                   object:nil];
        return self;
    }    
    return nil;
}

- (void) show:(NSWindow *)window
{
    if (!mPanel) {
        [NSBundle loadNibNamed:@"MLAmiKoPatientSheet" owner:self];
        
        // Set formatters
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [mWeight_kg setFormatter:formatter];
        [mHeight_cm setFormatter:formatter];
    }
    
    [NSApp beginSheet:mPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
    
    // Show the dialog
    [mPanel makeKeyAndOrderFront:self];
    
    // Start modal session
    mModalSession = [NSApp beginModalSessionForWindow:mPanel];
    [NSApp runModalSession:mModalSession];
    
    // Retrieves contacts from local patient database
    [self updateAmiKoAddressBookTableView];
    [mNotification setStringValue:@""];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(newSmartCardData:)
                                                 name:@"smartCardDataAcquired"
                                               object:nil];
}

- (void) remove
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"smartCardDataAcquired"
                                                  object:nil];

    [NSApp endModalSession:mModalSession];
    [NSApp endSheet:mPanel];
    [mPanel orderOut:nil];
    [mPanel close];
}

#pragma mark -

- (BOOL) stringIsNilOrEmpty:(NSString*)str
{
    return !(str && str.length);
}

- (void) resetFieldsColors
{
    mFamilyName.backgroundColor = [NSColor clearColor];
    mGivenName.backgroundColor = [NSColor clearColor];
    mBirthDate.backgroundColor = [NSColor clearColor];
    mPostalAddress.backgroundColor = [NSColor clearColor];
    mCity.backgroundColor = [NSColor clearColor];
    mZipCode.backgroundColor = [NSColor clearColor];
}

- (void) checkFields
{
    [self resetFieldsColors];
    
    if ([self stringIsNilOrEmpty:[mFamilyName stringValue]]) {
        mFamilyName.backgroundColor = [NSColor lightRed];
    }
    if ([self stringIsNilOrEmpty:[mGivenName stringValue]]) {
        mGivenName.backgroundColor = [NSColor lightRed];
    }
    if ([self stringIsNilOrEmpty:[mBirthDate stringValue]]) {
        mBirthDate.backgroundColor = [NSColor lightRed];
    }
    if ([self stringIsNilOrEmpty:[mPostalAddress stringValue]]) {
        mPostalAddress.backgroundColor = [NSColor lightRed];
    }
    if ([self stringIsNilOrEmpty:[mCity stringValue]]) {
        mCity.backgroundColor = [NSColor lightRed];
    }
    if ([self stringIsNilOrEmpty:[mZipCode stringValue]]) {
        mZipCode.backgroundColor = [NSColor lightRed];
    }
}

- (void) resetAllFields
{
    [self resetFieldsColors];
    
    [mFamilyName setStringValue:@""];
    [mGivenName setStringValue:@""];
    [mBirthDate setStringValue:@""];
    [mCity setStringValue:@""];
    [mZipCode setStringValue:@""];
    [mWeight_kg setStringValue:@""];
    [mHeight_cm setStringValue:@""];
    [mPostalAddress setStringValue:@""];
    [mZipCode setStringValue:@""];
    [mCity setStringValue:@""];
    [mCountry setStringValue:@""];
    [mPhone setStringValue:@""];
    [mEmail setStringValue:@""];
    [mFemaleButton setState:NSOnState];
    [mMaleButton setState:NSOffState];
    
    mPatientUUID = nil;
    
    [mNotification setStringValue:@""];
}

- (void) setAllFields:(MLPatient *)p
{
    if (p.familyName!=nil)
        [mFamilyName setStringValue:p.familyName];
    if (p.givenName!=nil)
        [mGivenName setStringValue:p.givenName];
    if (p.birthDate!=nil)
        [mBirthDate setStringValue:p.birthDate];
    if (p.city!=nil)
        [mCity setStringValue:p.city];
    if (p.zipCode!=nil)
        [mZipCode setStringValue:p.zipCode];
    if (p.weightKg>0)
        [mWeight_kg setStringValue:[NSString stringWithFormat:@"%d", p.weightKg]];
    if (p.heightCm>0)
        [mHeight_cm setStringValue:[NSString stringWithFormat:@"%d", p.heightCm]];
    if (p.phoneNumber!=nil)
        [mPhone setStringValue:p.phoneNumber];
    if (p.country!=nil)
        [mCity setStringValue:p.city];
    if (p.country!=nil)
        [mCountry setStringValue:p.country];
    if (p.postalAddress!=nil)
        [mPostalAddress setStringValue:p.postalAddress];
    if (p.emailAddress!=nil)
        [mEmail setStringValue:p.emailAddress];
    if (p.phoneNumber!=nil)
        [mPhone setStringValue:p.phoneNumber];
    if (p.uniqueId!=nil)
        mPatientUUID = p.uniqueId;
    if (p.gender!=nil) {
        if ([p.gender isEqualToString:@"woman"]) {
            mFemale = TRUE;
            [mFemaleButton setState:NSOnState];
            [mMaleButton setState:NSOffState];
        } else {
            mFemale = FALSE;
            [mFemaleButton setState:NSOffState];
            [mMaleButton setState:NSOnState];
        }
    }
}

- (MLPatient *) getAllFields
{
    long largetRowId = [mPatientDb getLargestRowId];
    
    MLPatient *patient = [[MLPatient alloc] init];
    patient.rowId = largetRowId + 1;
    patient.familyName = [mFamilyName stringValue];
    patient.givenName = [mGivenName stringValue];
    patient.birthDate = [mBirthDate stringValue];
    patient.city = [mCity stringValue];
    patient.zipCode = [mZipCode stringValue];
    patient.postalAddress = [mPostalAddress stringValue];
    patient.weightKg = [mWeight_kg intValue];
    patient.heightCm = [mHeight_cm intValue];
    patient.country = [mCountry stringValue];
    patient.phoneNumber = [mPhone stringValue];
    patient.emailAddress = [mEmail stringValue];
    patient.gender = [mFemaleButton state]==NSOnState ? @"woman" : @"man";
    
    return patient;
}

- (void) friendlyNote
{
    [mNotification setStringValue:[NSString stringWithFormat:NSLocalizedString(@"The contact was saved in the %@ address book", nil), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]]];
}

- (void) addPatient:(MLPatient *)patient
{
    mSelectedPatient = patient;
    mPatientUUID = [mPatientDb addEntry:patient];
    mSearchFiltered = FALSE;
    [mSearchKey setStringValue:@""];
    [self updateAmiKoAddressBookTableView];
    [self friendlyNote];
}

- (void) setSelectedPatient:(MLPatient *)patient
{
    mSelectedPatient = patient;
}

- (MLPatient *) retrievePatient
{
    return mSelectedPatient;
}

- (MLPatient *) retrievePatientWithUniqueID:(NSString *)uniqueID
{
    return [mPatientDb getPatientWithUniqueID:uniqueID];
}

- (BOOL) patientExistsWithID:(NSString *)uniqueID
{
    MLPatient *p = [self retrievePatientWithUniqueID:uniqueID];
    return p!=nil;
}

- (NSString *) retrievePatientAsString
{
    NSString *p = @"";
    if (mSelectedPatient!=nil) {
        return [mSelectedPatient asString];
    }
    return p;
}

- (NSString *) retrievePatientAsString:(NSString *)searchKey
{
    NSString *p = @"";
    // Retrieves first best match from patient sqlite database
    mArrayOfPatients = [mPatientDb getPatientsWithKey:searchKey];
    if ([mArrayOfPatients count]>0) {
        MLPatient *r = [mArrayOfPatients objectAtIndex:0];
        return [r asString];
    }
    return p;
}

- (BOOL) validateFields:(MLPatient *)patient
{
    BOOL valid = TRUE;
    
    [self resetFieldsColors];
    
    if ([self stringIsNilOrEmpty:patient.familyName]) {
        mFamilyName.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.givenName]) {
        mGivenName.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.birthDate]) {
        mBirthDate.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.postalAddress]) {
        mPostalAddress.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.city]) {
        mCity.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    if ([self stringIsNilOrEmpty:patient.zipCode]) {
        mZipCode.backgroundColor = [NSColor lightRed];
        valid = FALSE;
    }
    
    return valid;
}

- (void) updateAmiKoAddressBookTableView
{
    mArrayOfPatients = [mPatientDb getAllPatients];
    mABContactsVisible=NO;
    [mTableView reloadData];
    [self setNumPatients:[mArrayOfPatients count]];
}

#pragma mark - Notifications

// NSControlTextDidChangeNotification
- (void) controlTextDidChange:(NSNotification *)notification {
    /*
     NSTextField *textField = [notification object];
     if (textField==mFamilyName)
     NSLog(@"%@", [textField stringValue]);
     */
    [self checkFields];
}

#pragma mark - Actions

- (IBAction) onSearchDatabase:(id)sender
{
    NSString *searchKey = [mSearchKey stringValue];
    [mFilteredArrayOfPatients removeAllObjects];
    if (![self stringIsNilOrEmpty:searchKey]) {
        for (MLPatient *p in mArrayOfPatients) {
            NSString *searchKeyLower = [searchKey lowercaseString];
            if ([[p.familyName lowercaseString] hasPrefix:searchKeyLower] || [[p.givenName lowercaseString] hasPrefix:searchKeyLower] ||
                [[p.postalAddress lowercaseString] hasPrefix:searchKeyLower] || [p.zipCode hasPrefix:searchKeyLower]) {
                [mFilteredArrayOfPatients addObject:p];
            }
        }
    }
    if (mFilteredArrayOfPatients!=nil) {
        if ([mFilteredArrayOfPatients count]>0) {
            [self setNumPatients:[mFilteredArrayOfPatients count]];
            mSearchFiltered = TRUE;
        } else {
            if ([searchKey length]>0) {
                [self setNumPatients:0];
                mSearchFiltered = TRUE;
            } else {
                [self setNumPatients:[mArrayOfPatients count]];
                mSearchFiltered = FALSE;
            }
        }
    } else {
        [self setNumPatients:[mArrayOfPatients count]];
        mSearchFiltered = FALSE;
    }
    [mTableView reloadData];
}

- (IBAction) onSelectFemale:(id)sender
{
    if ([sender isKindOfClass:[NSButton class]]) {
        mFemale = TRUE;
        [mFemaleButton setState:NSOnState];
        [mMaleButton setState:NSOffState];
    }
}

- (IBAction) onSelectMale:(id)sender
{
    if ([sender isKindOfClass:[NSButton class]]) {
        mFemale = FALSE;
        [mFemaleButton setState:NSOffState];
        [mMaleButton setState:NSOnState];
    }
}

- (IBAction) onCancel:(id)sender
{
    [self remove];
}

- (IBAction) onSavePatient:(id)sender
{
    if (mPatientDb!=nil) {
        MLPatient *patient = [self getAllFields];
        if ([self validateFields:patient]) {
            if (mPatientUUID!=nil && [mPatientUUID length]>0) {
                patient.uniqueId = mPatientUUID;
            }
            if ([mPatientDb getPatientWithUniqueID:mPatientUUID]==nil) {
                mPatientUUID = [mPatientDb addEntry:patient];
            } else {
                mPatientUUID = [mPatientDb insertEntry:patient];
            }
            mSearchFiltered = FALSE;
            [mSearchKey setStringValue:@""];
            [self updateAmiKoAddressBookTableView];
            [self friendlyNote];
        }
    }
}

- (IBAction) onNewPatient:(id)sender
{
    [self resetAllFields];
    [self updateAmiKoAddressBookTableView];
}

- (IBAction) onDeletePatient:(id)sender
{
    NSInteger row = [mTableView selectedRow];
    if (mABContactsVisible==NO) {
        MLPatient *p = nil;
        if (mSearchFiltered) {
            p = mFilteredArrayOfPatients[row];
        }
        else {
            p = mArrayOfPatients[row];
        }
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"OK"];
        if ([MLUtilities isGermanApp]) {
            [alert setMessageText:@"Kontakt löschen?"];
            [alert setInformativeText:@"Wollen Sie diesen Kontakt wirklich aus dem AmiKo Adressbuch löschen?"];
        }
        else if ([MLUtilities isFrenchApp]) {
            [alert setMessageText:@"Supprimer le contact?"];
            [alert setInformativeText:@"Êtes-vous sûr de vouloir supprimer ce contact du carnet d'adresses CoMed?"];
        }
        [alert setAlertStyle:NSInformationalAlertStyle];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:(__bridge void * _Nullable)(p)];
    }
}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode==NSAlertSecondButtonReturn) {
        MLPatient *p = (__bridge MLPatient *)contextInfo;
        if ([mPatientDb deleteEntry:p]) {
            [self deletePatientFolder:p withBackup:YES];
            [self resetAllFields];
            [self updateAmiKoAddressBookTableView];
            [mNotification setStringValue:[NSString stringWithFormat:NSLocalizedString(@"The contact has been removed from the %@ Address Book", nil), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MLPrescriptionPatientDeleted" object:self];
        }
    }
}

- (void) deletePatientFolder:(MLPatient *)patient withBackup:(BOOL)backup
{
    NSString *documentsDir = [MLUtilities documentsDirectory];
    NSString *patientDir = [documentsDir stringByAppendingString:[NSString stringWithFormat:@"/%@", patient.uniqueId]];
    
    if (backup==YES) {
        NSString *backupDir = [documentsDir stringByAppendingString:[NSString stringWithFormat:@"/.%@", patient.uniqueId]];
        [[NSFileManager defaultManager] moveItemAtPath:patientDir toPath:backupDir error:nil];
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:patientDir error:nil];
    }
}

- (IBAction) onShowContacts:(id)sender
{
    [self resetAllFields];
    mSearchFiltered = FALSE;
    [mSearchKey setStringValue:@""];
    
    if (mABContactsVisible==NO) {
        MLContacts *contacts = [[MLContacts alloc] init];
        // Retrieves contacts from address book
        mArrayOfPatients = [contacts getAllContacts];
        [mTableView reloadData];
        mABContactsVisible = YES;
        [self setNumPatients:[mArrayOfPatients count]];
    }
    else {
        // Retrieves contacts from local patient database
        [self updateAmiKoAddressBookTableView];
    }
}

- (IBAction) onSelectPatient:(id)sender
{
    NSInteger row = [mTableView selectedRow];
    mSelectedPatient = nil;
    if (mSearchFiltered) {
        mSelectedPatient = mFilteredArrayOfPatients[row];
    }
    else {
        mSelectedPatient = mArrayOfPatients[row];
    }

    if (mSelectedPatient) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MLPrescriptionPatientChanged" object:self];
    }

    [self remove];
}


- (void) setNumPatients:(NSInteger)numPatients
{
    if (mABContactsVisible) {
        [mNumPatients setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Address Book Mac (%ld)", nil), numPatients]];
    }
    else {
        [mNumPatients setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Address Book App", nil),
                                      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"],
                                      numPatients]];
    }
}

- (MLPatient *) getContactAtRow:(NSInteger)row
{
    if (mSearchFiltered)
        return mFilteredArrayOfPatients[row];

    if (mArrayOfPatients!=nil)
        return mArrayOfPatients[row];

    return nil;
}

/**
 - NSTableViewDataSource -
 */
- (NSInteger) numberOfRowsInTableView: (NSTableView *)tableView
{
    if (mSearchFiltered) {
        return [mFilteredArrayOfPatients count];
    }
    if (mArrayOfPatients!=nil) {
        return [mArrayOfPatients count];
    }
    return 0;
}

/**
 - NSTableViewDataDelegate -
 */
- (NSView *) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    MLPatient *p = [self getContactAtRow:row];
    if (p!=nil) {
        NSString *cellStr = [NSString stringWithFormat:@"%@ %@", p.familyName, p.givenName];
        cellView.textField.stringValue = cellStr;
        if (p.databaseType==eAddressBook) {
            cellView.textField.textColor = [NSColor grayColor];
        } else {
            cellView.textField.textColor = [NSColor blackColor];
        }
        return cellView;
    }
    return nil;
}

- (void) tableViewSelectionDidChange: (NSNotification *)notification
{
    if ([notification object] == mTableView) {       
        NSInteger row = [[notification object] selectedRow];
        NSTableRowView *rowView = [mTableView rowViewAtRow:row makeIfNecessary:NO];
        
        MLPatient *p = [self getContactAtRow:row];
        mPatientUUID = p.uniqueId;
        
        [self resetAllFields];
        [self setAllFields:p];
        
        [rowView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleRegular];

        [mNotification setStringValue:@""];
    }
}

@end
