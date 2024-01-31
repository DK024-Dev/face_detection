import 'dart:developer';
import 'dart:ui' as ui;
import 'package:divyanshu_assignment/src/core/configuration.dart';
import 'package:camera/camera.dart';
import 'package:divyanshu_assignment/src/services/face_detection.dart';
import 'package:divyanshu_assignment/src/services/face_marks.dart';
import 'package:divyanshu_assignment/src/services/save_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'common_widget/common_button.dart';
import 'common_widget/common_toast.dart';
import 'common_widget/theme_layer_box.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  CameraController? _controller;
  late double height;
  late double width;
  bool isCameraInitialized = false;
  bool isRearCameraSelected = true;
  ui.Image? image;
  List<Face> faces = [];
  XFile? selectedFile;

  @override
  void initState() {
    onCameraSelected();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      onCameraSelected();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = _controller;
    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }
    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      log('Error occured while taking picture: $e');
      return null;
    }
  }

  void onCameraSelected() async {
    final cameras = await availableCameras();
    final previousCameraController = _controller;
    // Instantiating the camera controller
    final CameraController cameraController = CameraController(
      cameras[isRearCameraSelected ? 0 : 1],
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Dispose the previous controller
    await previousCameraController?.dispose();

    // Replace with the new controller
    if (mounted) {
      setState(() {
        _controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    // Initialize controller
    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      log('Error initializing camera: $e');
    }

    // Update the Boolean
    if (mounted) {
      setState(() {
        isCameraInitialized = _controller!.value.isInitialized;
      });
    }
  }

  Future<void> openGalleryView() async {
    final ImagePicker picker = ImagePicker();
    // Pick an image.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    setState(() => selectedFile = image);
    if (image != null) {
      await detectFace(image);
    }
  }

  //On caputre image
  Future<void> onCaptureImage() async {
    XFile? rawImage = await takePicture();
    setState(() => selectedFile = rawImage);
    await detectFace(rawImage);
  }

  Future<void> detectFace(XFile? xFile) async {
    if (xFile != null) {
      image = await imageFromFile(xFile);
      faces = await FaceDetectionService()
          .processinngImage(InputImage.fromFilePath(xFile.path));
      setState(() {});
      if (faces.length > 1) {
        if (!mounted) return;
        showToast(context, msg: moreThanOneFace);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorConstant.blackColor,
        leading: image != null
            ? IconButton(
                onPressed: () {
                  setState(() {
                    image = null;
                    selectedFile = null;
                  });
                },
                icon: Icon(
                  Icons.close_rounded,
                  color: ColorConstant.whiteColor,
                ),
              )
            : const SizedBox(),
        actions: [
          if (image != null)
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.more_vert_rounded,
                color: ColorConstant.whiteColor,
              ),
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: image != null
                ? FittedBox(
                    child: SizedBox(
                      width: image!.width.toDouble(),
                      height: image!.height.toDouble(),
                      child: CustomPaint(
                        painter: FacePainter(
                          image: image!,
                          faces: faces,
                        ),
                      ),
                    ),
                  )
                : isCameraInitialized
                    ? CameraPreview(_controller!)
                    : const Center(child: CircularProgressIndicator()),
          ),
          Container(
            color: ColorConstant.blackColor,
            height: height / 3.5,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 25,
              horizontal: 25,
            ),
            child: image != null ? editSection() : pickImageSection(),
          )
        ],
      ),
    );
  }

  Widget pickImageSection() {
    return Column(
      children: [
        IconButton(
          onPressed: () async => onCaptureImage(),
          icon: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                CupertinoIcons.circle,
                size: width * 0.2,
                color: ColorConstant.whiteColor.withOpacity(0.5),
              ),
              Icon(
                CupertinoIcons.circle_fill,
                size: width * 0.16,
                color: ColorConstant.whiteColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => openGalleryView(),
              icon: Icon(
                CupertinoIcons.photo,
                color: ColorConstant.whiteColor,
                size: 33,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  isCameraInitialized = false;
                });
                onCameraSelected();
                setState(() {
                  isRearCameraSelected = !isRearCameraSelected;
                });
              },
              icon: Icon(
                CupertinoIcons.arrow_2_circlepath,
                color: ColorConstant.whiteColor,
                size: 33,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget editSection() {
    return Column(
      children: [
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  image = null;
                  selectedFile = null;
                });
              },
              child: Icon(
                CupertinoIcons.arrow_turn_up_left,
                color: ColorConstant.whiteColor,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              backMenuHead,
              style: TextStyle(
                color: ColorConstant.whiteColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Row(
            children: [
              ThemeLayerBox(text: box1),
              ThemeLayerBox(text: box2),
            ],
          ),
        ),
        CommonButton(
          text: saveButton,
          onPressed: () {
            if (faces.length > 1) {
              showToast(context, msg: moreThanOneFace);
            } else if (selectedFile != null) {
              SaveToGallery().saveImage(selectedFile!.path);
              setState(() {
                image = null;
                selectedFile = null;
              });
              showToast(context, msg: imgSavedToGallery);
            } else {
              showToast(context, msg: imgNotSaved);
            }
          },
        ),
      ],
    );
  }
}
