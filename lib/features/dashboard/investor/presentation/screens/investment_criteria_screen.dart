import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '/core/constants/app_constants.dart';
import '/models/investor.dart';
import '/providers/investor_provider.dart';

class InvestmentCriteriaScreen extends ConsumerStatefulWidget {
  const InvestmentCriteriaScreen({super.key});

  @override
  ConsumerState<InvestmentCriteriaScreen> createState() =>
      _InvestmentCriteriaScreenState();
}

class _InvestmentCriteriaScreenState
    extends ConsumerState<InvestmentCriteriaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _minInvestmentController = TextEditingController();
  final _maxInvestmentController = TextEditingController();
  final _notesController = TextEditingController();

  List<String> _selectedIndustries = [];
  List<String> _selectedStages = [];

  @override
  void initState() {
    super.initState();
    _loadExistingCriteria();
  }

  void _loadExistingCriteria() {
    final criteria = ref.read(investorsProvider).myCriteria;
    if (criteria != null) {
      _minInvestmentController.text = criteria.minInvestment.toString();
      _maxInvestmentController.text = criteria.maxInvestment.toString();
      _notesController.text = criteria.additionalNotes ?? '';
      setState(() {
        _selectedIndustries = List.from(criteria.industries);
        _selectedStages = List.from(criteria.stages);
      });
    }
  }

  @override
  void dispose() {
    _minInvestmentController.dispose();
    _maxInvestmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleIndustry(String industry) {
    setState(() {
      if (_selectedIndustries.contains(industry)) {
        _selectedIndustries.remove(industry);
      } else {
        _selectedIndustries.add(industry);
      }
    });
  }

  void _toggleStage(String stage) {
    setState(() {
      if (_selectedStages.contains(stage)) {
        _selectedStages.remove(stage);
      } else {
        _selectedStages.add(stage);
      }
    });
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedIndustries.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one industry'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_selectedStages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one investment stage'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final criteria = InvestmentCriteria(
        industries: _selectedIndustries,
        stages: _selectedStages,
        minInvestment: double.parse(_minInvestmentController.text.trim()),
        maxInvestment: double.parse(_maxInvestmentController.text.trim()),
        additionalNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final success =
          await ref.read(investorsProvider.notifier).updateCriteria(criteria);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Investment criteria saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (mounted) {
        final error = ref.read(investorsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save criteria'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final investorsState = ref.watch(investorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Criteria'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Introduction
              Card(
                color: theme.colorScheme.primary.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Set your investment preferences to find matching projects',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Investment Range
              Text(
                'Investment Range',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minInvestmentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minimum (\$)',
                        hintText: 'e.g., 50000',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxInvestmentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maximum (\$)',
                        hintText: 'e.g., 500000',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final max = double.tryParse(value);
                        if (max == null) {
                          return 'Invalid';
                        }
                        final min = double.tryParse(
                            _minInvestmentController.text);
                        if (min != null && max < min) {
                          return 'Must be > min';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Industries
              Text(
                'Preferred Industries',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select industries you want to invest in',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.industries.map((industry) {
                  final isSelected = _selectedIndustries.contains(industry);
                  return FilterChip(
                    label: Text(industry),
                    selected: isSelected,
                    onSelected: (_) => _toggleIndustry(industry),
                    selectedColor:
                        theme.colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: theme.colorScheme.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Investment Stages
              Text(
                'Investment Stages',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select stages you prefer to invest in',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.investmentStages.map((stage) {
                  final isSelected = _selectedStages.contains(stage);
                  return FilterChip(
                    label: Text(stage),
                    selected: isSelected,
                    onSelected: (_) => _toggleStage(stage),
                    selectedColor:
                        theme.colorScheme.secondary.withOpacity(0.2),
                    checkmarkColor: theme.colorScheme.secondary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Additional Notes
              Text(
                'Additional Notes (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Any specific requirements or preferences...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              FilledButton(
                onPressed: investorsState.isLoading ? null : _handleSave,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: investorsState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Criteria',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
