/* logic for wine data registration with camera */

part of 'orchestrator.dart';

extension WineScannerCameraLogic on _WineScannerPageState {

  // take pictures of labels with camera
  Future<void> _takePhotos() async {
    if (kIsWeb) {                       // in Chrome upload images
      _showUploadDialog();
    } else {                            // handy takes pictures
      final front = await _picker.pickImage(source: ImageSource.camera);
      if (front == null) return;
      final back = await _picker.pickImage(source: ImageSource.camera);
      if (back == null) return;
      final Uint8List frontBytes = await front.readAsBytes();
      final Uint8List backBytes = await back.readAsBytes();

      setState(() {
        _frontBytes = frontBytes;
        _backBytes = backBytes;
      });
      _showConfirmationDialog();
    }
  }


  // upload labels in chrome
  void _showUploadDialog() {
    Uint8List? frontBytes;
    Uint8List? backBytes;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    AppConstants.uploadTitel,
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    // front label
                    icon: const Icon(Icons.upload_file, size: 20),
                    label: const Text(AppConstants.uploadFrontLabelButton),
                    style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final front = await _picker.pickImage(
                          source: ImageSource.gallery);
                      if (front == null) return;
                      final bytes = await front.readAsBytes();
                      setDialogState(() => frontBytes = bytes);
                    },
                  ),
                  if (frontBytes != null) ...[
                    const SizedBox(height: 6),
                    const Text(AppConstants.succFrontLabel,
                        style: TextStyle(color: AppConstants.successGreen)),
                  ],
                  const SizedBox(height: 16),
                  // back label
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file, size: 20),
                    label: const Text(AppConstants.uploadBackLabelButton),
                    style: ElevatedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final back = await _picker.pickImage(
                          source: ImageSource.gallery);
                      if (back == null) return;
                      final bytes = await back.readAsBytes();
                      setDialogState(() => backBytes = bytes);
                    },
                  ),
                  if (backBytes != null) ...[
                    const SizedBox(height: 6),
                    const Text(AppConstants.succBackLabel,
                        style: TextStyle(color: AppConstants.successGreen)),
                  ],
                ],
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              actionsAlignment: MainAxisAlignment.end,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(AppConstants.cancelButton),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (frontBytes == null || backBytes == null) {
                      SnackbarMessages.showErrorBar(context, SnackbarMessages.picMissing);
                      return;
                    }
                    Navigator.pop(context);
                    setState(() {
                      _frontBytes = frontBytes;
                      _backBytes = backBytes;
                    });
                    _showConfirmationDialog();
                  },
                  child: const Text(AppConstants.confirmButton),
                ),
              ],
            );
          },
        );
      },
    );
  }


  // check if user is satisfied with pics (uploaded or taken)
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppConstants.confirmPhotosTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_frontBytes != null) ...[
              const Text(
                AppConstants.conftimFrontTitle,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              Image.memory(_frontBytes!, height: 150, fit: BoxFit.cover),
              const SizedBox(height: 10),
            ],
            if (_backBytes != null) ...[
              const Text(
                AppConstants.conftimBackTitle,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              Image.memory(_backBytes!, height: 150, fit: BoxFit.cover),
            ]
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);     // closes window and reopens camera
              _takePhotos();
            },
            child: const Text(AppConstants.retakePicButton),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);     // closes window and starts LLM-analyzing
              _analyzeImages();
            },
            child: const Text(AppConstants.analysisButton),
          ),
        ],
      ),
    );
  }


  // extract data with gemini -->
  Future<void> _analyzeImages() async {
    if (_frontBytes == null || _backBytes == null) return; // works only with both pictures
    if (_isLoading) return;                                // no double requests

    setState(() => _isLoading = true);

    try {
     final result = await _wineRepository.analyzeLabel(_frontBytes!, _backBytes!,); // give pics to gemini
      setState(() {
        _wineData = result;                             // results in map<attribute, data>
      });
    } catch (e) {
      debugPrint("Error with analysis: $e");
      SnackbarMessages.showErrorBar(context, SnackbarMessages.analysisFailed);
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
