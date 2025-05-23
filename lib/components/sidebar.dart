import 'package:flutter/material.dart';
import 'package:math_buddy_v1/components/reusable-modal.dart';

class Sidebar extends StatelessWidget {
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  const Sidebar({
    required this.onItemSelected,
    required this.onLogout,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      child: Container(
        color: Colors.lightBlueAccent,
        child: Column(
          children: [
            // Menu Header with White Background
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'MENU',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Sidebar Options
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSidebarItem(
                    Icons.home_outlined,
                    'Halaman Utama',
                    0,
                    context,
                  ),
                  _buildSidebarItem(
                    Icons.account_circle_outlined,
                    'Profil',
                    1,
                    context,
                  ),
                  _buildSidebarItem(
                    Icons.addchart_outlined,
                    'Pencapaian Saya',
                    2,
                    context,
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 2,
                    color: Colors.white.withOpacity(0.7),
                    margin: const EdgeInsets.symmetric(vertical: 20),
                  ),

                  InkWell(
                    onTap: () {
                      showConfirmationDialog(
                        context: context,
                        title: "Log Keluar",
                        message: "Adakah anda pasti mahu log keluar?",
                        onConfirm: () {
                          onLogout();
                        },
                        onCancel: () {
                          Navigator.of(context).pop();
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        // vertical: 15,
                        horizontal: 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_outlined,
                            color: Colors.white,
                            size: screenWidth * 0.09,
                          ),
                          // const SizedBox(width: 15),
                          Text(
                            'LOG KELUAR',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to create sidebar items
  Widget _buildSidebarItem(
    IconData icon,
    String title,
    int pageIndex,
    context,
  ) {
    double screenWidth = MediaQuery.of(context).size.width;
    return ListTile(
      leading: Icon(icon, color: Colors.black, size: screenWidth * 0.09),
      title: Padding(
        padding: EdgeInsets.only(left: 20),
        child: Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            // fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      onTap: () {
        onItemSelected(pageIndex);
      },
    );
  }
}

void showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
  required VoidCallback onCancel,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return ConfirmationDialog(
        title: title,
        message: message,
        onConfirm: () {
          onConfirm();
          Navigator.of(context).pop();
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      );
    },
  );
}
