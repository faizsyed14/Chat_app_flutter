import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _firebase = FirebaseAuth.instance;

class authScreen extends StatefulWidget {
  const authScreen({super.key});

  @override
  State<authScreen> createState() => _authScreenState();
}

class _authScreenState extends State<authScreen> {
  final _form = GlobalKey<FormState>();
  var _islogin = true;
  var _enteredEmail = '';
  var _enteredpassword = '';
  var _enteredUsername = "";
  File? _selectedImage;
  var _isAuthenticating = false;
  void _submit() async {
    final isvalid = _form.currentState!.validate();
    if (!isvalid) {
      // show error
      return;
    }
    if (!_islogin && _selectedImage == null) {
      // show error
      return;
    }
    _form.currentState!.save();
    // print(_enteredEmail);
    // print(_enteredpassword);
    try {
      setState(() {
        _isAuthenticating = true;
      });
      if (_islogin) {
        final userCredential = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredpassword);
      } else {
        final userCredential = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredpassword);
        final Storageref = FirebaseStorage.instance
            .ref()
            .child("User_images")
            .child("${userCredential.user!.uid}.jpg");
        await Storageref.putFile(_selectedImage!);
        final imageurl = await Storageref.getDownloadURL();
        await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredential.user!.uid)
            .set({
          "username": _enteredUsername,
          "email": _enteredEmail,
          "image_url": imageurl,
        });
        // print(userCredential);
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == "email-already-in-use") {
        //....
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.message ?? 'Authentication Failed'),
      ));
      setState(() {
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(
                  top: 20,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Form(
                        key: _form,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_islogin)
                              UserImagePicker(
                                onPickImage: (pickedImage) {
                                  _selectedImage = pickedImage;
                                },
                              ),
                            TextFormField(
                              decoration:
                                  InputDecoration(labelText: 'Email Address'),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains("@")) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                _enteredEmail = newValue!;
                              },
                            ),
                            if (!_islogin)
                              TextFormField(
                                decoration:
                                    InputDecoration(labelText: "Username"),
                                enableSuggestions: false,
                                onSaved: (newValue) {
                                  _enteredUsername = newValue!;
                                },
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value.trim().length < 4) {
                                    return "Please enter Atleast 4 characters";
                                  }
                                  return null;
                                },
                              ),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Password',
                              ),
                              // to hide the password characters
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be atleast 6 characters long.';
                                }
                                return null;
                              },
                              onSaved: (newValue) {
                                _enteredpassword = newValue!;
                              },
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            if (_isAuthenticating) CircularProgressIndicator(),
                            if (!_isAuthenticating)
                              ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .background),
                                child: Text(_islogin ? 'Login' : 'Signup'),
                              ),
                            if (!_isAuthenticating)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _islogin = !_islogin;
                                  });
                                },
                                child: Text(_islogin
                                    ? 'Create an account'
                                    : 'I already have an account.'),
                              )
                          ],
                        )),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
