public class SendOTPtoCustomer {
		public static string getOTPFromTwillio(String phNumber){
            String toNumber = '+'+phNumber;
            String otp = String.valueOf(Math.round(Math.random() * 899999) + 100000);

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:TwillioNamedCreds/2010-04-01/Accounts/AC8dbd55640f4f26a6fa5f9f393d17e6ed/Messages.json');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setBody(
                'To=' + EncodingUtil.urlEncode(toNumber, 'UTF-8') +
                '&From=' + EncodingUtil.urlEncode('+19782880064', 'UTF-8') +
                '&Body=' + EncodingUtil.urlEncode('Your OTP is: ' + otp, 'UTF-8')
            );

            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('Response: ' + res.getBody());
            httpResponseWrapper wrapResp = (httpResponseWrapper)JSON.deserialize(res.getBody(), httpResponseWrapper.class);
            String retOTP = wrapResp.body.split('is: ')[1];
            return retOTP;
        }
        @InvocableMethod(label='Send SMS OTP' description='Send the SMS with OTP')
        public static List<SentOTPResponse> sendOTPSMS(List<SendOTPRequest> requests) {
            String PhoneNum = (String) requests[0].phoneNumber;
            String strOTP = getOTPFromTwillio(PhoneNum);
            // Create the response for the agent
            SentOTPResponse response = new SentOTPResponse();
            response.sentOTP = strOTP;
            return new List<SentOTPResponse>{ response };
        }

        public class SendOTPRequest {
            @InvocableVariable(required=true description='Phone Number To Send OTP')
            public String phoneNumber;
        }

        public class SentOTPResponse {
            @InvocableVariable(description='OTP Value Returned')
            public String sentOTP;
        }

        public class httpResponseWrapper{
            public String messaging_service_sid{get;set;}
            public String num_media{get;set;}
            public String error_message{get;set;}
            public String num_segments{get;set;}
            public String error_code{get;set;}
            public String price{get;set;}
            public String direction{get;set;}
            public String price_unit{get;set;}
            public String date_updated{get;set;}
            public String sid{get;set;}
            public String date_sent{get;set;}
            public String status{get;set;}
            public String date_created{get;set;}
            public String body{get;set;}
            public String to{get;set;}
            public String api_version{get;set;}
            public String uri{get;set;}
            public String account_sid{get;set;}
        }
}