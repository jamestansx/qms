import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:qms_staff/appointment/model/patient.dart';
import 'package:qms_staff/appointment/services/appointment.dart';

class AddAppointmentPage extends StatefulWidget {
  const AddAppointmentPage({super.key});

  @override
  State<AddAppointmentPage> createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final dateOfBirthController = TextEditingController();
  DateTime? scheduledTime;
  Patient? patient;

  Widget patientPopupItem(
    BuildContext context,
    Patient item,
    bool isDisabled,
    bool isSelected,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: !isSelected
          ? null
          : BoxDecoration(
              border: Border.all(color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(5),
              color: Colors.white,
            ),
      child: ListTile(
        selected: isSelected,
        title: Text("${item.firstName} ${item.lastName}"),
        leading: CircleAvatar(child: Text(item.firstName.isNotEmpty ? item.firstName[0] : "")),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Add New Appointment'),
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              DropdownSearch<Patient>(
                validator: (item) {
                  if (item == null) {
                    return "Please Select a Patient";
                  }
                  return null;
                },
                onChanged: (item) {
                  patient = item;
                },
                itemAsString: (item) => "${item.firstName} ${item.lastName}",
                items: (filter, _) => AppointmentRepo().fetchPatients(filter),
                filterFn: (item, str) =>
                    item.firstName.toLowerCase().contains(str.toLowerCase()) ||
                    item.lastName.toLowerCase().contains(str.toLowerCase()),
                compareFn: (item1, item2) => item1.id == item2.id,
                popupProps: PopupProps.menu(
                  showSelectedItems: true,
                  showSearchBox: true,
                  itemBuilder: patientPopupItem,
                ),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                child: TextFormField(
                  controller: dateOfBirthController,
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2400),
                    );

                    if (!context.mounted) return;

                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );

                    if (date != null && time != null) {
                      scheduledTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    }

                    if (scheduledTime != null) {
                      dateOfBirthController.text =
                          scheduledTime!.toLocal().toString();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: "Appointment Date",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    prefixIcon: const Icon(Icons.calendar_month),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          child: const Text("Submit"),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final _ = await AppointmentRepo()
                  .book(patient!.id, scheduledTime!.toUtc());
              if (!context.mounted) return;
              Navigator.of(context).pop();
            }
          },
        )
      ],
    );
  }
}
