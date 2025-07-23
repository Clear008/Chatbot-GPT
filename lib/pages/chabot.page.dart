import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChabotPage extends StatefulWidget {
  const ChabotPage({super.key});

  @override
  State<ChabotPage> createState() => _ChabotPageState();
}

class _ChabotPageState extends State<ChabotPage> {
  List<Map<String, String>> messages = [];
  TextEditingController userController = TextEditingController();
  ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DWM Chatbot", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, "/");
              },
              icon: const Icon(Icons.logout, color: Colors.white))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg['role'] == 'user';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisAlignment:
                    isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.green[50] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isUser ? Colors.green : Colors.deepPurple.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isUser ? "Moi :" : "GPT :",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                msg['content'] ?? "",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: userController,
                    decoration: InputDecoration(
                      hintText: "Posez une question...",
                      suffixIcon: const Icon(Icons.chat),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.deepPurple),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: sendMessage,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
    );
  }

  void sendMessage() {
    String question = userController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "content": question});
    });

    userController.clear();

    Uri uri = Uri.parse("https://api.openai.com/v1/chat/completions");

    var headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${dotenv.env['OPENAI_API_KEY']}"
    };

    var body = {
      "model": "gpt-3.5-turbo",
      "messages": messages,
    };

    http
        .post(uri, headers: headers, body: json.encode(body))
        .then((resp) {
      var data = json.decode(resp.body);
      print("Réponse brute : ${resp.body}");

      if (data['choices'] != null) {
        String answer = data['choices'][0]['message']['content'];
        setState(() {
          messages.add({"role": "assistant", "content": answer});
          scrollToBottom();
        });
      } else if (data['error'] != null) {
        String errorMsg = data['error']['message'];
        setState(() {
          messages.add({"role": "assistant", "content": "Erreur API : $errorMsg"});
          scrollToBottom();
        });
      }
    })
        .catchError((err) {
      print("Erreur lors de l'appel API : $err");
      setState(() {
        messages.add({
          "role": "assistant",
          "content": "Une erreur s'est produite. Réessaie plus tard."
        });
        scrollToBottom();
      });
    });
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
