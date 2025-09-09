import 'package:auction_demo/screens/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PlantImagesList extends StatefulWidget {
  final String docId; // which item this belongs to
  final String folderName; // storage folder from Firestore

  const PlantImagesList({
    Key? key,
    required this.docId,
    required this.folderName,
  }) : super(key: key);

  @override
  State<PlantImagesList> createState() => _PlantImagesListState();
}

class _PlantImagesListState extends State<PlantImagesList> {
  final Map<String, String> selectedImages = {}; // tracks selection

  Future<List<String>> fetchImagesFromFolder(String folderPath) async {
    try {
      final ref = FirebaseStorage.instance.ref(folderPath);
      final ListResult result = await ref.listAll();
      final urls = await Future.wait(result.items.map((ref) => ref.getDownloadURL()));
      return urls;
    } catch (e) {
      print("Error fetching images: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: fetchImagesFromFolder(widget.folderName),
      builder: (context, imgSnapshot) {
        if (!imgSnapshot.hasData || imgSnapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final urls = imgSnapshot.data!;
        // main image = selected or default first one
        final mainImage = selectedImages[widget.docId] ?? urls[0];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Main image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
              child: AspectRatio(
                aspectRatio: 0.77,
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, mainImage),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      mainImage,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Thumbnails row
            SizedBox(
              height: 100,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kDefaultPadding / 2),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: urls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, index) {
                    final url = urls[index];
                    final isSelected = url == mainImage;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedImages[widget.docId] = url;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? kPrimaryColor : Colors.transparent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => Scaffold(
          backgroundColor: kBackgroundColor,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 60,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Color.fromARGB(255, 149, 190, 158), size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
