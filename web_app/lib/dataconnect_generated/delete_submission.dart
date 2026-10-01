part of 'generated.dart';

class DeleteSubmissionVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  DeleteSubmissionVariablesBuilder(this._dataConnect, );
  Deserializer<DeleteSubmissionData> dataDeserializer = (dynamic json)  => DeleteSubmissionData.fromJson(jsonDecode(json));
  
  Future<OperationResult<DeleteSubmissionData, void>> execute() {
    return ref().execute();
  }

  MutationRef<DeleteSubmissionData, void> ref() {
    
    return _dataConnect.mutation("DeleteSubmission", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class DeleteSubmissionSubmissionDelete {
  final String id;
  DeleteSubmissionSubmissionDelete.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSubmissionSubmissionDelete otherTyped = other as DeleteSubmissionSubmissionDelete;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  DeleteSubmissionSubmissionDelete({
    required this.id,
  });
}

@immutable
class DeleteSubmissionData {
  final DeleteSubmissionSubmissionDelete? submission_delete;
  DeleteSubmissionData.fromJson(dynamic json):
  
  submission_delete = json['submission_delete'] == null ? null : DeleteSubmissionSubmissionDelete.fromJson(json['submission_delete']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final DeleteSubmissionData otherTyped = other as DeleteSubmissionData;
    return submission_delete == otherTyped.submission_delete;
    
  }
  @override
  int get hashCode => submission_delete.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (submission_delete != null) {
      json['submission_delete'] = submission_delete!.toJson();
    }
    return json;
  }

  DeleteSubmissionData({
    this.submission_delete,
  });
}

