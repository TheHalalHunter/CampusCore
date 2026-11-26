part of 'generated.dart';

class GetUserVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetUserVariablesBuilder(this._dataConnect, );
  Deserializer<GetUserData> dataDeserializer = (dynamic json)  => GetUserData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetUserData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetUserData, void> ref() {
    
    return _dataConnect.query("GetUser", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetUserUser {
  final String username;
  final String email;
  GetUserUser.fromJson(dynamic json):
  
  username = nativeFromJson<String>(json['username']),
  email = nativeFromJson<String>(json['email']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserUser otherTyped = other as GetUserUser;
    return username == otherTyped.username && 
    email == otherTyped.email;
    
  }
  @override
  int get hashCode => Object.hashAll([username.hashCode, email.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['username'] = nativeToJson<String>(username);
    json['email'] = nativeToJson<String>(email);
    return json;
  }

  GetUserUser({
    required this.username,
    required this.email,
  });
}

@immutable
class GetUserData {
  final GetUserUser? user;
  GetUserData.fromJson(dynamic json):
  
  user = json['user'] == null ? null : GetUserUser.fromJson(json['user']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserData otherTyped = other as GetUserData;
    return user == otherTyped.user;
    
  }
  @override
  int get hashCode => user.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (user != null) {
      json['user'] = user!.toJson();
    }
    return json;
  }

  GetUserData({
    this.user,
  });
}

