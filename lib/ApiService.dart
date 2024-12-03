import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models/UserModel.dart';


class ApiService {
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com/posts';

  static Future<List<UserModel>> fetchPosts() async {
    final response = await http.get(Uri.parse(_baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  static Future<UserModel> fetchPostDetail(int postId) async {
    final response = await http.get(Uri.parse('$_baseUrl/$postId'));

    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load post detail');
    }
  }
}
