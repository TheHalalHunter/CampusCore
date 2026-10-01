part of 'generated.dart';

class GetQuizVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetQuizVariablesBuilder(this._dataConnect, );
  Deserializer<GetQuizData> dataDeserializer = (dynamic json)  => GetQuizData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetQuizData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetQuizData, void> ref() {
    
    return _dataConnect.query("GetQuiz", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetQuizQuiz {
  final String title;
  GetQuizQuiz.fromJson(dynamic json):
  
  title = nativeFromJson<String>(json['title']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetQuizQuiz otherTyped = other as GetQuizQuiz;
    return title == otherTyped.title;
    
  }
  @override
  int get hashCode => title.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['title'] = nativeToJson<String>(title);
    return json;
  }

  GetQuizQuiz({
    required this.title,
  });
}

@immutable
class GetQuizData {
  final GetQuizQuiz? quiz;
  GetQuizData.fromJson(dynamic json):
  
  quiz = json['quiz'] == null ? null : GetQuizQuiz.fromJson(json['quiz']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetQuizData otherTyped = other as GetQuizData;
    return quiz == otherTyped.quiz;
    
  }
  @override
  int get hashCode => quiz.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (quiz != null) {
      json['quiz'] = quiz!.toJson();
    }
    return json;
  }

  GetQuizData({
    this.quiz,
  });
}

