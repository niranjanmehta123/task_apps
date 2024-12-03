import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ApiService.dart';
import 'PostDetailScreen.dart';
import 'models/UserModel.dart';

class PostListScreen extends StatefulWidget {
  @override
  _PostListScreenState createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  late Future<List<UserModel>> postsFuture;
  Map<int, Timer?> timers = {};
  Map<int, int> remainingTimes = {};
  Set<int> _readPosts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title: Text('Posts')

      ),
      body: FutureBuilder<List<UserModel>>(
        future: postsFuture,
        builder: (context, snapshot) {
          if (isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No data available.'));
          }

          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final isRead = _readPosts.contains(post.id);
              final timerText = remainingTimes[post.id]?.toString() ?? '';

              if (!timers.containsKey(post.id)) {
                startTimer(post.id);
              }

              return GestureDetector(
                onTap: () async {
                  pauseTimer(post.id);
                  await markAsRead(post.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(postId: post.id),
                    ),
                  ).then((_) => startTimer(post.id));
                },
                child: Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: isRead ? Colors.white : Colors.yellow[100],
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                post.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10),
                        Column(
                          children: [
                            Icon(Icons.timer, color: Colors.grey[700]),
                            SizedBox(height: 5),
                            Text(
                              timerText,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> initializeData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String>? readPosts = prefs.getStringList('readPosts');
    if (readPosts != null) {
      setState(() {
        _readPosts = readPosts.map((id) => int.parse(id)).toSet();
      });
    }

    List<String>? storedPosts = prefs.getStringList('posts');
    List<UserModel>? localPosts;

    if (storedPosts != null) {
      localPosts = storedPosts
          .map((post) => UserModel.fromJson(json.decode(post)))
          .toList();
    }

    postsFuture = ApiService.fetchPosts();
    if (localPosts != null) {
      setState(() {
        postsFuture = Future.value(localPosts);
      });
    }

    postsFuture.then((apiPosts) async {
      prefs.setStringList(
        'posts',
        apiPosts.map((post) => json.encode(post.toJson())).toList(),
      );
      setState(() {
        isLoading = false;
      });
    });
  }

  void startTimer(int id) {
    if (!timers.containsKey(id)) {
      remainingTimes[id] = Random().nextInt(20) + 10; // Random duration
    }

    timers[id] = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingTimes[id]! > 0) {
          remainingTimes[id] = remainingTimes[id]! - 1;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void pauseTimer(int id) {
    timers[id]?.cancel();
    timers.remove(id);
  }

  Future<void> markAsRead(int postId) async {
    setState(() {
      _readPosts.add(postId);
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        'readPosts', _readPosts.map((id) => id.toString()).toList());
  }

  @override
  void dispose() {
    timers.values.forEach((timer) => timer?.cancel());
    super.dispose();
  }
}
