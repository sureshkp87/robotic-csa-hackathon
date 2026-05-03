global class GetMessagingContentAction {

    global class ActionInput {
        @InvocableVariable(
            label='Messaging Session Id'
            description='The Id of the MessagingSession record'
            required=true
        )
        global Id messagingSessionId;

        @InvocableVariable(
            label='Dispute Id'
            description='The Id of the open Dispute record'
            required=true
        )
        global Id disputeId;

        @InvocableVariable(
            label='Dispute Item Id'
            description='The Id of the DisputeItem record'
            required=true
        )
        global Id disputeItemId;
    }

    global class ActionOutput {
        @InvocableVariable(
            label='Content Version Id'
            description='The ContentVersion Id of the uploaded image'
        )
        global String contentVersionId;

        @InvocableVariable(
            label='Image Base64'
            description='Base64 encoded image string'
        )
        global String imageBase64;

        @InvocableVariable(
            label='Media Type'
            description='MIME type of the image e.g. image/jpeg'
        )
        global String mediaType;

        @InvocableVariable(
            label='Status'
            description='Success or error message'
        )
        global String status;

        @InvocableVariable(
            label='Error'
            description='Error message if something went wrong'
        )
        global String error;
    }

    @InvocableMethod(
        label='Get Messaging Content'
        description='Retrieves the latest image uploaded to a MessagingSession and returns it as Base64 for AI extraction'
        category='Financial Services'
    )
    global static List<ActionOutput> execute(List<ActionInput> inputs) {
        List<ActionOutput> outputs = new List<ActionOutput>();

        for (ActionInput input : inputs) {
            ActionOutput output = new ActionOutput();

            try {
                if (input.messagingSessionId == null) {
                    output.error  = 'Messaging Session Id is required.';
                    output.status = 'Error';
                    outputs.add(output);
                    continue;
                }

                // Step 1 — Find ContentDocumentLink
                // linked to the MessagingSession
                List<ContentDocumentLink> cdls = [
                    SELECT Id,
                           ContentDocumentId,
                           LinkedEntityId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId = :input.messagingSessionId
                    ORDER BY SystemModstamp DESC
                    LIMIT 1
                ];

                if (cdls.isEmpty()) {
                    output.error  = 'No file found linked to this messaging session.';
                    output.status = 'Error';
                    outputs.add(output);
                    continue;
                }

                Id contentDocumentId = cdls[0].ContentDocumentId;

                // Step 2 — Fetch latest ContentVersion
                // with image bytes
                List<ContentVersion> cvs = [
                    SELECT Id,
                           Title,
                           FileType,
                           ContentSize,
                           VersionData,
                           ContentDocumentId
                    FROM ContentVersion
                    WHERE ContentDocumentId = :contentDocumentId
                      AND IsLatest = true
                    LIMIT 1
                ];

                if (cvs.isEmpty()) {
                    output.error  = 'ContentVersion not found for document.';
                    output.status = 'Error';
                    outputs.add(output);
                    continue;
                }

                ContentVersion cv = cvs[0];

                // Step 3 — Validate it is an image
                Set<String> imageTypes = new Set<String>{
                    'JPG', 'JPEG', 'PNG', 'GIF', 'HEIC', 'WEBP'
                };

                if (!imageTypes.contains(
                    cv.FileType?.toUpperCase())
                ) {
                    output.error  = 'Uploaded file is not a supported image type. ' +
                                    'Please upload a JPG, PNG or GIF.';
                    output.status = 'Error';
                    outputs.add(output);
                    continue;
                }

                // Step 4 — Convert to Base64
                String base64Image = EncodingUtil.base64Encode(
                    cv.VersionData
                );

                String mimeType = 'image/' +
                    cv.FileType.toLowerCase()
                        .replace('jpg', 'jpeg');

                // Step 5 — Populate output
                output.contentVersionId = cv.Id;
                output.imageBase64      = base64Image;
                output.mediaType        = mimeType;
                output.status           = 'Success';

                System.debug('GetMessagingContentAction: ' +
                    'Successfully retrieved image ' + cv.Title +
                    ' (' + cv.ContentSize + ' bytes) ' +
                    'for MessagingSession ' + input.messagingSessionId);

            } catch (Exception e) {
                output.error  = 'Error retrieving content: ' + e.getMessage();
                output.status = 'Error';
                System.debug('GetMessagingContentAction ERROR: ' +
                    e.getMessage());
            }

            outputs.add(output);
        }

        return outputs;
    }
}