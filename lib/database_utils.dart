import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mysql1/mysql1.dart';

// Check if phone number exists in Firestore
Future<bool> phoneNumberExists(String phoneNumber) async {
  final firestore = FirebaseFirestore.instance;
  final result = await firestore.collection('users')
      .where('phoneNumber', isEqualTo: phoneNumber)
      .get();
  return result.docs.isNotEmpty;
}

// Save user info to Firestore
Future<void> saveUserToFirestore(String uid, String username, String email, String phoneNumber) async {
  final firestore = FirebaseFirestore.instance;
  await firestore.collection('users').doc(uid).set({
    'username': username,
    'email': email,
    'phoneNumber': phoneNumber,
    'createdAt': Timestamp.now(),
  });
}

// Save user info to MySQL
Future<void> saveUserToMySQL(String uid, String username, String email, String phoneNumber) async {
  final connection = await MySqlConnection.connect(ConnectionSettings(
    host: 'your-mysql-host',
    port: 3306,
    user: 'your-mysql-user',
    db: 'your-database',
    password: 'your-mysql-password',
  ));

  await connection.query(
    'INSERT INTO users (uid, username, email, phoneNumber) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE username=VALUES(username), email=VALUES(email), phoneNumber=VALUES(phoneNumber)',
    [uid, username, email, phoneNumber],
  );

  await connection.close();
}
