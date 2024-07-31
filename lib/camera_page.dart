import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;
import 'dart:typed_data';

class CameraDemo extends HookWidget {
  const CameraDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cameraController = useState<CameraController?>(null);
    final errorMessage = useState<String?>(null);
    final isCameraInitialized = useState(false);
    final averageBrightness = useState<double>(0.0);
    final isOccluded = useState<bool>(false);

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
            enableAudio: false,
          );

          await controller.initialize();
          if (!controller.value.isInitialized) {
            errorMessage.value = '无法初始化摄像头';
            return;
          }

          // 设置固定的相机参数
          await _setFixedCameraParameters(controller);

          cameraController.value = controller;
          isCameraInitialized.value = true;

          // 开始图像流
          await controller.startImageStream((CameraImage image) {
            // 计算图像亮度和检测遮挡
            final BrightnessInfo brightnessInfo = calculateBrightnessInfo(image);
            averageBrightness.value = brightnessInfo.averageBrightness;
            isOccluded.value = detectOcclusion(brightnessInfo);
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
      appBar: AppBar(title: const Text('摄像头演示')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (errorMessage.value != null)
              Text(errorMessage.value!)
            else if (isCameraInitialized.value)
              Column(
                children: [
                  Text('平均亮度: ${averageBrightness.value.toStringAsFixed(2)}'),
                  Text('摄像头状态: ${isOccluded.value ? '被遮挡' : '正常'}'),
                ],
              )
            else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Future<void> _setFixedCameraParameters(CameraController controller) async {
    // 设置固定的曝光和白平衡
    await controller.setExposureMode(ExposureMode.locked);
    await controller.setExposureOffset(0.0);  // 你可能需要根据实际情况调整这个值

    // 如果需要，你还可以设置其他参数，比如ISO、对焦模式等
    await controller.setExposurePoint(Offset(0.5, 0.5));
    await controller.setFocusMode(FocusMode.locked);
    // await controller.setFocusPoint(Offset(0.5, 0.5));
  }

  BrightnessInfo calculateBrightnessInfo(CameraImage image) {
    final Uint8List luminances = image.planes[0].bytes;
    int totalLuminance = 0;
    List<int> luminanceValues = [];

    // 计算所有像素的亮度总和和收集亮度值
    for (int i = 0; i < luminances.length; i++) {
      totalLuminance += luminances[i];
      luminanceValues.add(luminances[i]);
    }

    // 计算平均亮度（0-255范围）
    double averageLuminance = totalLuminance / luminances.length;

    // 计算标准差
    double sumSquaredDifferences = 0;
    for (int value in luminanceValues) {
      sumSquaredDifferences += math.pow(value - averageLuminance, 2);
    }
    double standardDeviation = math.sqrt(sumSquaredDifferences / luminances.length);

    // 将亮度值标准化到0-1范围
    return BrightnessInfo(
      averageBrightness: averageLuminance / 255.0,
      standardDeviation: standardDeviation / 255.0,
    );
  }

  bool detectOcclusion(BrightnessInfo info) {
    // 设置阈值来检测遮挡
    const double occlusionBrightnessThreshold = 0.4; // 亮度阈值
    const double occlusionStdDevThreshold = 0.05; // 标准差阈值

    return info.averageBrightness < occlusionBrightnessThreshold &&
        info.standardDeviation < occlusionStdDevThreshold;
  }
}

class BrightnessInfo {
  final double averageBrightness;
  final double standardDeviation;

  BrightnessInfo({required this.averageBrightness, required this.standardDeviation});
}