import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:social_app/services/user_service.dart';
import 'package:social_app/services/post_service.dart';
//import 'package:social_app/services/post_type_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _client;
  late final UserService userService;
  late final PostService postService;
  late final SupabaseClient supabase;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal() {
    _client = Supabase.instance.client;
    
    // تهيئة الخدمات
    userService = UserService(_client);
    postService = PostService(_client);
    //postTypeService = PostTypeService(_client);
  }
}