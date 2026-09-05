import 'package:flutter/material.dart';

import '../../../app/ui/app_ui.dart';
import '../../../core/domain/identity.dart';
import '../../audit/domain/audit_models.dart';
import '../organization_service.dart';

class OfficerEditorResult {
  const OfficerEditorResult({
    required this.officerId,
    required this.wasCreated,
  });

  final StableId officerId;
  final bool wasCreated;
}

class OfficerEditorDialog extends StatefulWidget {
  const OfficerEditorDialog({super.key, required this.service, this.officer});

  final OrganizationService service;
  final OfficerRowView? officer;

  @override
  State<OfficerEditorDialog> createState() => _OfficerEditorDialogState();
}

class _OfficerEditorDialogState extends State<OfficerEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late OfficerPosition _position;
  Committee? _committee;
  String? _serviceError;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final officer = widget.officer;
    _nameController = TextEditingController(text: officer?.fullName ?? '');
    _position = officer?.position ?? OfficerPosition.member;
    _committee = officer?.committee;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.officer != null;
    return AppDialogFrame(
      title: isEditing ? 'Edit Officer' : 'Add Officer',
      status: _serviceError == null
          ? null
          : InlineStatusPanel(
              title: 'Officer could not be saved',
              message: _serviceError!,
              tone: InlineStatusTone.error,
            ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('profileOfficerSubmitButton'),
          onPressed: _isSubmitting ? null : _submit,
          icon: _isSubmitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Save Officer'),
        ),
      ],
      children: [
        Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('profileOfficerNameField'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Officer name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<OfficerPosition>(
                key: const Key('profileOfficerPositionField'),
                initialValue: _position,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Position'),
                items: const [
                  DropdownMenuItem(
                    value: OfficerPosition.member,
                    child: Text('Member', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: OfficerPosition.head,
                    child: Text('Head', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _position = value);
                        }
                      },
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<Committee?>(
                key: const Key('profileOfficerCommitteeField'),
                initialValue: _committee,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Committee'),
                items: const [
                  DropdownMenuItem<Committee?>(
                    value: null,
                    child: Text(
                      'No committee',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem<Committee?>(
                    value: Committee.finance,
                    child: Text(
                      'Finance Committee',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem<Committee?>(
                    value: Committee.audit,
                    child: Text(
                      'Audit Committee',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                validator: (value) {
                  if (_position == OfficerPosition.head && value == null) {
                    return 'Committee heads must be assigned to a committee.';
                  }
                  return null;
                },
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _committee = value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _serviceError = null);
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _serviceError = 'Fix the highlighted fields before saving.';
      });
      return;
    }
    setState(() => _isSubmitting = true);
    final result = await widget.service.saveOfficer(
      SaveOfficerCommand(
        id: widget.officer?.id,
        fullName: _nameController.text,
        position: _position,
        committee: _committee,
      ),
    );
    if (!mounted) {
      return;
    }
    if (result.isInvalid) {
      setState(() {
        _isSubmitting = false;
        _serviceError = result.summary;
      });
      return;
    }
    Navigator.pop(
      context,
      OfficerEditorResult(
        officerId: result.officerId!,
        wasCreated: widget.officer == null,
      ),
    );
  }
}
