part of 'generated.dart';

class CreateSubmissionVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  CreateSubmissionVariablesBuilder(this._dataConnect, );
  Deserializer<CreateSubmissionData> dataDeserializer = (dynamic json)  => CreateSubmissionData.fromJson(jsonDecode(json));
  
  Future<OperationResult<CreateSubmissionData, void>> execute() {
    return ref().execute();
  }

  MutationRef<CreateSubmissionData, void> ref() {
    
    return _dataConnect.mutation("CreateSubmission", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class CreateSubmissionSubmissionInsert {
  final String id;
  CreateSubmissionSubmissionInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSubmissionSubmissionInsert otherTyped = other as CreateSubmissionSubmissionInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateSubmissionSubmissionInsert({
    required this.id,
  });
}

@immutable
class CreateSubmissionData {
  final CreateSubmissionSubmissionInsert submission_insert;
  CreateSubmissionData.fromJson(dynamic json):
  
  submission_insert = CreateSubmissionSubmissionInsert.fromJson(json['submission_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateSubmissionData otherTyped = other as CreateSubmissionData;
    return submission_insert == otherTyped.submission_insert;
    
  }
  @override
  int get hashCode => submission_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['submission_insert'] = submission_insert.toJson();
    return json;
  }

  CreateSubmissionData({
    required this.submission_insert,
  });
}

