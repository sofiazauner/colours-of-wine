/* user interface for the start screen  */

part of 'orchestrator.dart';

extension WineScannerStartView on _WineScannerPageState {

  // regular homescreen (first thing you see after login)
  Widget _buildStartView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/logo.png',
          height: 230,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        Text(
          "Discover you wine",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          icon: const Icon(Icons.photo_camera),
          label: const Text("Scan label"),
          onPressed: _takePhotos,
        ),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text("Fill data in manually"),
          onPressed: _enterManually,
        ),
        const SizedBox(height: 5),
        ElevatedButton.icon(
          icon: const Icon(Icons.history),
          label: const Text("Previous searches"),
          onPressed: _showSearchHistory,
        ),
      ],
    );
  }
}