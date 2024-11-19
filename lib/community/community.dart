import 'package:flutter/material.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<Map<String, String>> posts = []; // List to store posts
  final TextEditingController _controller = TextEditingController();

  void _addPost() {
    String postText = _controller.text.trim();
    if (postText.isNotEmpty) {
      setState(() {
        posts.add({
          'content': postText,
          'timestamp': DateTime.now().toString(),
          'user': 'User ${posts.length + 1}', // Placeholder for user name
        });
        _controller.clear(); // Clear the text field after submission
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (BuildContext context, int index) {
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(posts[index]['user']!),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(posts[index]['content']!),
                        SizedBox(height: 4),
                        Text(
                          posts[index]['timestamp']!,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Write something...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addPost,
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
