import 'package:flutter/material.dart';
import 'package:qms_staff/dashboard/services/wearables_repo.dart';

class AddWearableDialog extends StatefulWidget {
  const AddWearableDialog({super.key});

  @override
  State<AddWearableDialog> createState() => _AddWearableDialogState();
}

class _AddWearableDialogState extends State<AddWearableDialog> {
  final formKey = GlobalKey<FormState>();
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Add New Device'),
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: "Device Name",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  prefixIcon: const Icon(Icons.devices),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          child: const Text("Add Device"),
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              final device = await WearablesRepo().register(
                textController.text,
              );
              if (!context.mounted) return;
              Navigator.pop(context, true);
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: SelectableText(device),
                    actions: [
                      TextButton(
                        child: Text("Ok"),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                },
              );
            }
            if (!context.mounted) return;
            Navigator.pop(context, false);
          },
        )
      ],
    );
  }
}
