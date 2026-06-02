import 'package:flutter/material.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController nearbylocController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController zipController = TextEditingController();

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      // Example: Use this data to send to your backend
      print("Name: ${nameController.text}");
      print("Phone: ${nearbylocController.text}");
      print("Street: ${streetController.text}");
      print("City: ${cityController.text}");
      print("State: ${stateController.text}");
      print("Zip: ${zipController.text}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Address Saved")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enter Address"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildField("House No", Icon(Icons.house),nameController),
              _buildField("Nearby location",Icon(Icons.near_me), nearbylocController, keyboard: TextInputType.phone),
              _buildField("Street Address", Icon(Icons.streetview),streetController),
              _buildField("City", Icon(Icons.location_city),cityController),
              _buildField("State", Icon(Icons.location_on),stateController),
              _buildField("Pin Code", Icon(Icons.pin),zipController, keyboard: TextInputType.number),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Save Address",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label,Icon icon, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          prefixIcon: icon,
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "$label is required";
          }
          return null;
        },
      ),
    );
  }
}
