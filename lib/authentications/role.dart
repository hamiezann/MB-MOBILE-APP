import 'package:flutter/material.dart';

class RoleSelector extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.grey.shade100,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onRoleChanged('student'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color:
                      selectedRole == 'student'
                          ? Colors.lightBlue
                          : Colors.transparent,
                  boxShadow:
                      selectedRole == 'student'
                          ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : [],
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color:
                          selectedRole == 'student'
                              ? Colors.white
                              : Colors.grey.shade700,
                      fontWeight:
                          selectedRole == 'student'
                              ? FontWeight.w600
                              : FontWeight.w500,
                      fontSize: 14,
                    ),
                    child: const Text("Pelajar"),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onRoleChanged('teacher'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color:
                      selectedRole == 'teacher'
                          ? Colors.amber
                          : Colors.transparent,
                  boxShadow:
                      selectedRole == 'teacher'
                          ? [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : [],
                ),
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color:
                          selectedRole == 'teacher'
                              ? Colors.white
                              : Colors.grey.shade700,
                      fontWeight:
                          selectedRole == 'teacher'
                              ? FontWeight.w600
                              : FontWeight.w500,
                      fontSize: 14,
                    ),
                    child: const Text("Guru"),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
