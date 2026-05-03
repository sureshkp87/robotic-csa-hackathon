trigger ContentVersionTrigger on ContentVersion (after insert) {
	for(ContentVersion cv : Trigger.new){
        ContentDistribution cd = new ContentDistribution(
                    Name                         = 'Dispute Evidence',
                    ContentVersionId             = cv.Id,
                    PreferencesAllowViewInBrowser = true,
                    PreferencesLinkLatestVersion  = true,
                    PreferencesNotifyOnVisit      = false,
                    PreferencesPasswordRequired   = false,
                    PreferencesAllowOriginalDownload = true
                );
                insert cd;
        /* 1. Get the ContentDocumentId (can be queried or from a trigger)
        Id myFileId = cd.ContentDocumentId; // Example ContentDocumentId
        Id targetRecordId = '005bm00000OX90HAAT'; // Example Account/User Id
        
        // 2. Create the link
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = myFileId;
        cdl.LinkedEntityId = targetRecordId; // Target record or user ID
        cdl.ShareType = 'V'; // 'V' for Viewer, 'C' for Collaborator, 'I' for Inferred [9]
        cdl.Visibility = 'AllUsers'; // 'AllUsers', 'InternalUsers', or 'SharedUsers' [9]
        */
        //insert cdl;
    }
}