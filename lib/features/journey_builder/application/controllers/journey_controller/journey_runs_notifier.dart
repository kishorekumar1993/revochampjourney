import 'package:flutter_riverpod/flutter_riverpod.dart';

class JourneyRunsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  JourneyRunsNotifier()
      : super([
          {
            'id': 'RUN-1049',
            'journeyName': 'Motor Insurance Journey',
            'user': 'john.doe@gmail.com',
            'status': 'Completed',
            'currentStep': 'Success',
            'progress': 1.0,
            'stepsCount': '7/7',
            'started': '12 mins ago',
            'data': {
              'fullName': 'John Doe',
              'dob': '25/08/1992',
              'mobile': '+91 9876543210',
              'email': 'john.doe@gmail.com',
              'gender': 'Male',
              'maritalStatus': 'Single',
              'vehicleNum': 'MH-12-PQ-9988',
              'vehicleMake': 'Toyota',
              'vehicleModel': 'Fortuner',
              'regYear': '2025',
              'nomineeName': 'Jane Doe',
              'nomineeRelation': 'Spouse',
              'panDoc': 'pan_uploaded.png',
              'drivingLicense': 'license_scan.jpg',
              'paymentMethod': 'UPI',
              'termsAccepted': 'true',
            },
          },
          {
            'id': 'RUN-1048',
            'journeyName': 'User KYC Onboarding',
            'user': 'alice.smith@yahoo.com',
            'status': 'In Progress',
            'currentStep': 'Facial Verification',
            'progress': 0.75,
            'stepsCount': '3/4',
            'started': '45 mins ago',
            'data': {
              'firstName': 'Alice',
              'lastName': 'Smith',
              'panNumber': 'DKFPD8812K',
              'panDoc': 'alice_pan.png',
              'aadhaarFront': 'aadhaar_front.jpg',
            },
          },
          {
            'id': 'RUN-1047',
            'journeyName': 'Personal Loan Application',
            'user': 'bob.jones@outlook.com',
            'status': 'Draft',
            'currentStep': 'Employment Details',
            'progress': 0.25,
            'stepsCount': '1/4',
            'started': '2 hours ago',
            'data': const {'fullName': 'Bob Jones', 'loanAmount': '25000'},
          },
          {
            'id': 'RUN-1046',
            'journeyName': 'Motor Insurance Journey',
            'user': 'sarah.k@hotmail.com',
            'status': 'Failed Validation',
            'currentStep': 'Nominee Details',
            'progress': 0.57,
            'stepsCount': '4/7',
            'started': '1 day ago',
            'data': {
              'fullName': 'Sarah Kerigan',
              'dob': '09/11/1988',
              'mobile': '+91 8877665544',
              'gender': 'Female',
              'vehicleNum': 'DL-03-AB-1122',
              'vehicleMake': 'Honda',
            },
          },
          {
            'id': 'RUN-1045',
            'journeyName': 'Service Feedback Survey',
            'user': 'steve.jobs@apple.com',
            'status': 'Completed',
            'currentStep': 'Contact Info',
            'progress': 1.0,
            'stepsCount': '3/3',
            'started': '2 days ago',
            'data': {
              'overallRating': '5 - Highly Satisfied',
              'feedbackComments':
                  'Awesome builder platform! Love the laptop simulator feature.',
              'followUpEmail': 'steve.jobs@apple.com',
            },
          },
        ]);

  void addRun(Map<String, dynamic> run) {
    state = [run, ...state];
  }
}

final journeyRunsProvider =
    StateNotifierProvider<JourneyRunsNotifier, List<Map<String, dynamic>>>((
      ref,
    ) {
      return JourneyRunsNotifier();
    });
