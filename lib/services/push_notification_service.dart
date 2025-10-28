import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:incubation_app/services/local_notification_service.dart';

class PushNotificationService {
   

   static FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
   
   
   static Future<void> initialize() async {
     await firebaseMessaging.requestPermission();

     String? token = await firebaseMessaging.getToken();
     print('Firebase Messaging Token: $token');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received a message while in the foreground!');
        print('Message data: ${message.data}');
  
        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
        }
      });


      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // show local notification
        LocalNotificationService.showBasicNotification(
          message.notification?.title ?? 'إشعار جديد',
          message.notification?.body ?? '',
        );
        


      });

     
   }


    static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
      print('Handling a background message: ${message.messageId}');
    }
}