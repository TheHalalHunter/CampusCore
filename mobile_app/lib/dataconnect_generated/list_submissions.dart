part of 'generated.dart';

class ListSubmissionsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  ListSubmissionsVariablesBuilder(this._dataConnect, );
  Deserializer<ListSubmissionsData> dataDeserializer = (dynamic json)  => ListSubmissionsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<ListSubmissionsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<ListSubmissionsData, void> ref() {
    
    return _dataConnect.query("ListSubmissions", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class ListSubmissionsSubmissions {
  final int score;
  ListSubmissionsSubmissions.fromJson(dynamic json):
  
  score = nativeFromJson<int>(json['score']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListSubmissionsSubmissions otherTyped = other as ListSubmissionsSubmissions;
    return score == otherTyped.score;
    
  }
  @override
  int get hashCode => score.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['score'] = nativeToJson<int>(score);
    return json;
  }

  ListSubmissionsSubmissions({
    required this.score,
  });
}

@immutable
class ListSubmissionsData {
  final List<ListSubmissionsSubmissions> submissions;
  ListSubmissionsData.fromJson(dynamic json):
  
  submissions = (json['submissions'] as List<dynamic>)
        .map((e) => ListSubmissionsSubmissions.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final ListSubmissionsData otherTyped = other as ListSubmissionsData;
    return submissions == otherTyped.submissions;
    
  }
  @override
  int get hashCode => submissions.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['submissions'] = submissions.map((e) => e.toJson()).toList();
    return json;
  }

  ListSubmissionsData({
    required this.submissions,
  });
}

