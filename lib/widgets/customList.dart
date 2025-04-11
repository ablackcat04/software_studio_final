import 'package:flutter/material.dart';

class CustomListItemWidget extends StatelessWidget {
  final ListItemData itemData;
  final VoidCallback? onTap; // Optional callback for when the item is tapped

  const CustomListItemWidget({super.key, required this.itemData, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Makes the item tappable
      onTap: onTap, // Execute the callback when tapped
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align items to the top
          children: <Widget>[
            // --- Left side: Image Placeholder ---
            Container(
              width: 300.0,
              height: 200.0,
              margin: const EdgeInsets.only(right: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[300], // Placeholder background
                // You could add border, borderRadius etc. here
                // border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(
                  8.0,
                ), // Optional rounded corners
              ),
              // Display image if URL exists, otherwise show placeholder icon
              child:
                  itemData.imageUrl != null && itemData.imageUrl!.isNotEmpty
                      ? ClipRRect(
                        // Clip the image to the container's bounds/radius
                        borderRadius: BorderRadius.circular(
                          8.0,
                        ), // Match container's radius
                        child: Image.network(
                          itemData.imageUrl!,
                          fit: BoxFit.cover,
                          // Add error and loading builders for production apps
                          errorBuilder:
                              (context, error, stackTrace) => Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[600],
                                ),
                              ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                strokeWidth: 2.0,
                              ),
                            );
                          },
                        ),
                      )
                      : Center(
                        child: Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                      ), // Placeholder icon
            ),

            // --- Right side: Text Lines ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    itemData.title,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1, // Ensure title doesn't wrap excessively
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    itemData.subtitle1,
                    style: TextStyle(fontSize: 14.0, color: Colors.grey[800]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Conditionally display subtitle2 if it exists
                  if (itemData.subtitle2 != null &&
                      itemData.subtitle2!.isNotEmpty)
                    Padding(
                      // Add padding only if the text is shown
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        itemData.subtitle2!,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
}

class ListItemData {
  final String? imageUrl; // URL or asset path for the image (optional)
  final String title;
  final String subtitle1;
  final String? subtitle2; // Optional second subtitle

  // Constructor
  const ListItemData({
    this.imageUrl, // Make it optional if you might not always have an image
    required this.title,
    required this.subtitle1,
    this.subtitle2,
  });
}
