import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationController {
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    // You can navigate to specific screen when notification is tapped
    // For example:
    // Navigator.push(context, MaterialPageRoute(builder: (_) => ReportsScreen()));
  }
}
