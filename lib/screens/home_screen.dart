import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evbooking_user/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  Future<void> cancelRequest() async {
    if (_user != null) {
      try {
        await _databaseService.cancelRequest(_user!.uid);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  User? _user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();

  String? _selectedLocation;
  String? _selectedDestination;
  String? _selectedDesignation;
  String? _selectedLuggageStatus;
  String? _selectedPurpose;
  String? _otherPurposeText;

  final List<String> _locations = [
    'Gate A',
    'Gate B',
    'Gate C',
    'AS Block',
    'IB Block',
    'Cafeteria',
    'Aero Block',
    'Main Ground',
    'Boys Hostel',
    'Girls Hostel',
    'Main Parking',
    'South Parking',
    'Medical Centre',
    'Staff Quarters',
    'Badminton Court',
    'Learning Centre',
    'Sunflower Block',
    'Mechanical Block',
    'BIT Main Auditorium',
    'Indoor Badminton Court',
  ];

  final Map<String, List<String>> _purposesByDesignation = {
    'Student': ['Going home', 'Medical Center', 'Other'],
    'Faculty': ['Lecture', 'Meeting', 'DC Rounds', 'Guest Transport', 'Other'],
    'Technician': ['Other'],
  };

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  bool _isFormValid() {
    return _selectedLocation != null &&
        _selectedDestination != null &&
        _selectedDesignation != null &&
        _selectedLuggageStatus != null &&
        _selectedPurpose != null &&
        (_selectedPurpose != 'Other' || _otherPurposeText != null);
  }

  Future<void> signUserOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  // Function to submit request details to Firestore
  Future<void> _submitDetails() async {
    if (_user != null) {
      String purpose = _selectedPurpose == 'Other'
          ? _otherPurposeText ?? 'Unknown'
          : _selectedPurpose ?? 'Unknown';

      try {
        await _databaseService.createRequest(
          _user!.uid,
          _user!.displayName ?? 'Unknown',
          _user!.email ?? 'Unknown',
          _selectedLocation ?? 'Unknown',
          _selectedDestination ?? 'Unknown',
          _selectedDesignation ?? 'Unknown',
          _selectedLuggageStatus ?? 'Unknown',
          purpose,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _selectedDesignation = null;
          _selectedLuggageStatus = null;
          _selectedPurpose = null;
          _selectedLocation = null;
          _otherPurposeText = null;
          _selectedDestination = null;
        });
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit request: User not logged in'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fetch request status from Firestore
  Stream<Map<String, dynamic>?> streamLastRequestStatus(String uid) {
    return _firestore.collection('requests').doc(uid).snapshots().map(
        (snapshot) => snapshot.data()?['status'] != null
            ? {'status': snapshot.data()?['status']}
            : null);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _user != null
          ? _databaseService.streamLastRequestStatus(_user!.uid)
          : Stream.value(null),
      builder: (context, snapshot) {
        final requestData = snapshot.data;
        final requestStatus =
            requestData?['status'] ?? 'No recent request found';
        final canSubmit = requestStatus != 'pending';

        // Add cancel button logic
        if (requestStatus == 'pending' || requestStatus == 'approved') {
          Widget _ = ElevatedButton(
            onPressed: () => cancelRequest(),
            child: const Text('Cancel Request'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Home'),
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          drawer: Drawer(
            child: Column(
              children: <Widget>[
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.deepPurple, Colors.purple]),
                  ),
                  accountName: Text(_user?.displayName ?? ''),
                  accountEmail: Text(_user?.email ?? ''),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: _user?.photoURL != null
                        ? NetworkImage(_user!.photoURL!)
                        : null,
                    child: _user?.photoURL == null
                        ? Text(
                            _user?.displayName?.substring(0, 1) ?? 'G',
                            style: const TextStyle(fontSize: 40.0),
                          )
                        : null,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    Navigator.pop(context);
                    signUserOut();
                  },
                ),
              ],
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.purpleAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Display Request Status at the top
                      Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: requestStatus == 'approved'
                            ? Colors.green
                            : requestStatus == 'pending'
                                ? Colors.orange
                                : requestStatus == 'rejected'
                                    ? Colors.red
                                    : Colors.grey,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Request Status: ${requestStatus.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (requestStatus == 'pending')
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: ElevatedButton(
                                    onPressed: () => cancelRequest(),
                                    child: const Text('Cancel Request'),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Request form
                      Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Request EV',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Current Location
                              DropdownButtonFormField<String>(
                                value: _selectedLocation,
                                decoration: InputDecoration(
                                  labelText: 'Current Location',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                items: _locations.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedLocation = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              // Destination Location
                              DropdownButtonFormField<String>(
                                value: _selectedDestination,
                                decoration: InputDecoration(
                                  labelText: 'Destination Location',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                items: _locations
                                    .where((location) =>
                                        location != _selectedLocation)
                                    .map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedDestination = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              // Designation
                              DropdownButtonFormField<String>(
                                value: _selectedDesignation,
                                decoration: InputDecoration(
                                  labelText: 'Designation',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                items: <String>[
                                  'Student',
                                  'Faculty',
                                  'Technician'
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedDesignation = newValue;
                                    _selectedPurpose = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              // Luggage Status
                              DropdownButtonFormField<String>(
                                value: _selectedLuggageStatus,
                                decoration: InputDecoration(
                                  labelText: 'Luggage Available Status',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                items:
                                    <String>['Yes', 'No'].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedLuggageStatus = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              // Purpose Dropdown
                              DropdownButtonFormField<String>(
                                value: _selectedPurpose,
                                decoration: InputDecoration(
                                  labelText: 'Purpose',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                items: (_selectedDesignation != null
                                        ? _purposesByDesignation[
                                            _selectedDesignation]
                                        : ['Other'])
                                    ?.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedPurpose = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 20),

                              // Other Purpose Text Field
                              if (_selectedPurpose == 'Other') ...[
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Specify',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onChanged: (text) {
                                    setState(() {
                                      _otherPurposeText = text;
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Submit Button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  backgroundColor: Colors.deepPurple,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _isFormValid() && canSubmit
                                    ? () {
                                        _submitDetails();
                                      }
                                    : null,
                                child: const Text('Submit'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
