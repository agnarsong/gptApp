import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatApp(),
    );
  }
}

class ChatApp extends StatefulWidget {
  @override
  _ChatAppState createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  TextEditingController _textEditingController = TextEditingController();
  List<Message> messages = [];
  bool _isSending = false;

  String timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分钟前';
    } else {
      return '刚刚';
    }
  }


  Future<void> _sendMessage(String content) async {
    final message = Message(
      author: 'user',
      timestamp: DateTime.now(),
      content: content,
    );
    setState(() {
      messages.add(message);
    });

    _textEditingController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final response = await _fetchBotResponse(content);
      final botMessage = Message(
        author: 'bot',
        timestamp: DateTime.now(),
        content: response.trim(),
      );
      setState(() {
        messages.add(botMessage);
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<String> _fetchBotResponse(String content) async {
    // Replace with your OpenAI API key
    final apiKey = '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';
    final url = 'https://api.openai.com/v1/chat/completions';
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {'role': 'user', 'content': content}
      ],
    });

    final response = await http.post(Uri.parse(url), headers: headers, body: body);
    String decodedResponse = utf8.decode(response.bodyBytes);
    Map<String, dynamic> jsonResponse = jsonDecode(decodedResponse);

    return jsonResponse['choices'][0]['message']['content'];
  }

  Widget formatText(Text content) {
    final text = content.data!;
    if (text.startsWith('```') && text.endsWith('```')) {
      return SelectableText(
        text.substring(3, text.length - 3),
        style: TextStyle(fontFamily: 'Courier', backgroundColor: Colors.grey[200]),
      );
    }
    return SelectableText(text);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('聊天应用'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUser = message.author == 'user';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment:
                        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isUser)
                        CircleAvatar(
                          child: Icon(Icons.android),
                          backgroundColor: Colors.green,
                        ),
                      Flexible(
                        child: Container(
                          margin: EdgeInsets.all(8.0),
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            color: isUser ? Colors.blue : Colors.grey[300],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              formatText(Text(message.content,
                                  style: TextStyle(
                                      color: isUser ? Colors.white : Colors.black))),
                              Text(
                                timeAgo(message.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUser ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isUser)
                        CircleAvatar(
                          child: Icon(Icons.person),
                          backgroundColor: Colors.blue,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    decoration: InputDecoration(
                      hintText: '请输入消息',
                    ),
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        )
                      : Icon(Icons.send),
                  onPressed: () {
                    final value = _textEditingController.text.trim();
                    if (value.isNotEmpty) {
                      _sendMessage(value);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String author;
  final DateTime timestamp;
  final String content;

  Message({required this.author, required this.timestamp, required this.content});
}
