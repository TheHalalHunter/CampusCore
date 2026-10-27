part of 'generated.dart';

class CreateEnrollmentVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  CreateEnrollmentVariablesBuilder(this._dataConnect, );
  Deserializer<CreateEnrollmentData> dataDeserializer = (dynamic json)  => CreateEnrollmentData.fromJson(jsonDecode(json));
  
  Future<OperationResult<CreateEnrollmentData, void>> execute() {
    return ref().execute();
  }

  MutationRef<CreateEnrollmentData, void> ref() {
    
    return _dataConnect.mutation("CreateEnrollment", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class CreateEnrollmentEnrollmentInsert {
  final String id;
  CreateEnrollmentEnrollmentInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateEnrollmentEnrollmentInsert otherTyped = other as CreateEnrollmentEnrollmentInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateEnrollmentEnrollmentInsert({
    required this.id,
  });
}

@immutable
class CreateEnrollmentData {
  final CreateEnrollmentEnrollmentInsert enrollment_insert;
  CreateEnrollmentData.fromJson(dynamic json):
  
  enrollment_insert = CreateEnrollmentEnrollmentInsert.fromJson(json['enrollment_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateEnrollmentData otherTyped = other as CreateEnrollmentData;
    return enrollment_insert == otherTyped.enrollment_insert;
    
  }
  @override
  int get hashCode => enrollment_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['enrollment_insert'] = enrollment_insert.toJson();
    return json;
  }

  CreateEnrollmentData({
    required this.enrollment_insert,
  });
}

