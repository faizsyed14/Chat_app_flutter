import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthenticatedUser = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("chat")
            .orderBy(
              "createdAt",
              descending: true,
            )
            .snapshots(),
        builder: (ctx, chatSnapshots) {
          if (chatSnapshots.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
            return Center(
              child: Text("No messages found."),
            );
          }
          if (chatSnapshots.hasError) {
            return Center(
              child: Text("Error found."),
            );
          }
          final loadedmessges = chatSnapshots.data!.docs;
          return ListView.builder(
              padding: const EdgeInsets.only(
                bottom: 40,
                left: 13,
                right: 13,
              ),
              reverse: true,
              itemCount: loadedmessges.length,
              itemBuilder: (ctx, index) {
                final chatMessage = loadedmessges[index].data();
                final nextchatmessage = index + 1 < loadedmessges.length
                    ? loadedmessges[index + 1].data()
                    : null;
                final currentMessagesuserId = chatMessage["userId"];
                final nextMessageuserId =
                    nextchatmessage != null ? nextchatmessage["userId"] : null;
                final nextUserissame =
                    nextMessageuserId == currentMessagesuserId;
                if (nextUserissame) {
                  return MessageBubble.next(
                      message: chatMessage["text"],
                      isMe: AuthenticatedUser.uid == currentMessagesuserId);
                } else {
                  return MessageBubble.first(
                      userImage: chatMessage["UserImage"],
                      username: chatMessage["username"],
                      message: chatMessage["text"],
                      isMe: AuthenticatedUser.uid == currentMessagesuserId);
                }
              });
        });
  }
}
