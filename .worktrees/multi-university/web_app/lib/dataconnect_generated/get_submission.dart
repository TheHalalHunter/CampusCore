part of 'generated.dart';

class GetSubmissionVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetSubmissionVariablesBuilder(this._dataConnect, );
  Deserializer<GetSubmissionData> dataDeserializer = (dynamic json)  => GetSubmissionData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetSubmissionData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetSubmissionData, void> ref() {
    
    return _dataConnect.query("GetSubmission", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetSubmissionSubmission {
  final int score;
  GetSubmissionSubmission.fromJson(dynamic json):
  
  score = nativeFromJson<int>(json['score']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSubmissionSubmission otherTyped = other as GetSubmissionSubmission;
    return score == otherTyped.score;
    
  }
  @override
  int get hashCode => score.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['score'] = nativeToJson<int>(score);
    return json;
  }

  GetSubmissionSubmission({
    required this.score,
  });
}

@immutable
class GetSubmissionData {
  final GetSubmissionSubmission? submission;
  GetSubmissionData.fromJson(dynamic json):
  
  submission = json['submission'] == null ? null : GetSubmissionSubmission.fromJson(json['submission']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetSubmissionData otherTyped = other as GetSubmissionData;
    return submission == otherTyped.submission;
    
  }
  @override
  int get hashCode => submission.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (submission != null) {
      json['submission'] = submission!.toJson();
    }
    return json;
  }

  GetSubmissionData({
    this.submission,
  });
}

