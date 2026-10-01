part of 'generated.dart';

class UpdateSubmissionVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  UpdateSubmissionVariablesBuilder(this._dataConnect, );
  Deserializer<UpdateSubmissionData> dataDeserializer = (dynamic json)  => UpdateSubmissionData.fromJson(jsonDecode(json));
  
  Future<OperationResult<UpdateSubmissionData, void>> execute() {
    return ref().execute();
  }

  MutationRef<UpdateSubmissionData, void> ref() {
    
    return _dataConnect.mutation("UpdateSubmission", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class UpdateSubmissionSubmissionUpdate {
  final String id;
  UpdateSubmissionSubmissionUpdate.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSubmissionSubmissionUpdate otherTyped = other as UpdateSubmissionSubmissionUpdate;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  UpdateSubmissionSubmissionUpdate({
    required this.id,
  });
}

@immutable
class UpdateSubmissionData {
  final UpdateSubmissionSubmissionUpdate? submission_update;
  UpdateSubmissionData.fromJson(dynamic json):
  
  submission_update = json['submission_update'] == null ? null : UpdateSubmissionSubmissionUpdate.fromJson(json['submission_update']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final UpdateSubmissionData otherTyped = other as UpdateSubmissionData;
    return submission_update == otherTyped.submission_update;
    
  }
  @override
  int get hashCode => submission_update.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    if (submission_update != null) {
      json['submission_update'] = submission_update!.toJson();
    }
    return json;
  }

  UpdateSubmissionData({
    this.submission_update,
  });
}

