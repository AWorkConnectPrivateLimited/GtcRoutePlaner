import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database_utils.dart'; // Import the utility file
import 'main.dart'; // Import main.dart if needed for other components

class PhoneAuthPage extends StatefulWidget {
  @override
  _PhoneAuthPageState createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  String? verificationId;
  bool isCodeSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Authentication'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isCodeSent) ...[
                  Text(
                    'Enter your phone number',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.verifyPhoneNumber(
                        phoneNumber: _phoneController.text,
                        verificationCompleted: (PhoneAuthCredential credential) async {
                          await FirebaseAuth.instance.signInWithCredential(credential);
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            bool exists = await phoneNumberExists(user.phoneNumber ?? '');
                            if (exists) {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
                            } else {
                              setState(() {
                                verificationId = null;
                                isCodeSent = false;
                              });
                            }
                          }
                        },
                        verificationFailed: (FirebaseAuthException e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed.')));
                        },
                        codeSent: (String verificationId, int? resendToken) {
                          setState(() {
                            this.verificationId = verificationId;
                            isCodeSent = true;
                          });
                        },
                        codeAutoRetrievalTimeout: (String verificationId) {},
                      );
                    },
                    child: Text('Send Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Enter the OTP sent to your phone',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'OTP',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final credential = PhoneAuthProvider.credential(
                        verificationId: verificationId!,
                        smsCode: _otpController.text,
                      );

                      try {
                        await FirebaseAuth.instance.signInWithCredential(credential);
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          bool exists = await phoneNumberExists(user.phoneNumber ?? '');
                          if (!exists) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Additional Info'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: _usernameController,
                                      decoration: InputDecoration(
                                        labelText: 'Username',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      await saveUserToFirestore(user.uid, _usernameController.text, _emailController.text, user.phoneNumber ?? '');
                                      await saveUserToMySQL(user.uid, _usernameController.text, _emailController.text, user.phoneNumber ?? '');

                                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
                                    },
                                    child: Text('Save and Continue'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed.')));
                      }
                    },
                    child: Text('Verify OTP'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
