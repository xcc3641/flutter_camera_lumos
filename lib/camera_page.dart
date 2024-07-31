import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class CameraDemo extends HookWidget {
  const CameraDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cameraController = useState<CameraController?>(null);
    final errorMessage = useState<String?>(null);
    final isCameraInitialized = useState(false);

    useEffect(() {
      Future<void> initializeCamera() async {
        try {
          final cameras = await availableCameras();
          if (cameras.isEmpty) {
            errorMessage.value = '没有可用的摄像头';
            return;
          }

          final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          );

          final controller = CameraController(
            frontCamera,
            ResolutionPreset.medium,
          );

          await controller.initialize();
          if (!controller.value.isInitialized) {
            errorMessage.value = '无法初始化摄像头';
            return;
          }

          cameraController.value = controller;
          isCameraInitialized.value = true;

          // 开始图像流
          await controller.startImageStream((CameraImage image) {
            // 这里处理图像数据
            // 注意：这里的图像处理可能需要根据您的具体需求来实现
          });
        } catch (e) {
          errorMessage.value = '初始化摄像头时出错: $e';
        }
      }

      initializeCamera();

      return () {
        cameraController.value?.dispose();
      };
    }, []);

    return Scaffold(
      body: Center(
        child: errorMessage.value != null
            ? Text(errorMessage.value!)
            : isCameraInitialized.value
                ? const Text('摄像头已初始化，正在获取图像流')
                : const CircularProgressIndicator(),
      ),
    );
  }
}
