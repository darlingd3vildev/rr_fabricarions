import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rr_fabrication/models/product_model.dart';
import 'package:rr_fabrication/models/stage_model.dart';
import 'package:rr_fabrication/screens/admin/admin_drawer.dart';
import 'package:rr_fabrication/services/product_service.dart';
import 'package:rr_fabrication/services/stage_service.dart';
import 'package:rr_fabrication/services/storage_service.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  final StageService _stageService = StageService();
  final StorageService _storageService = StorageService();

  void _showAddOrEditProductDialog({
    ProductModel? existingProduct,
    required List<StageModel> availableStages,
  }) {
    final isEditing = existingProduct != null;
    final nameController =
        TextEditingController(text: isEditing ? existingProduct.name : '');
    final descriptionController =
        TextEditingController(text: isEditing ? existingProduct.description : '');
    final imageUrlController =
        TextEditingController(text: isEditing ? (existingProduct.imageUrl ?? '') : '');
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    // Selected stage IDs for this product (retaining order)
    final selectedStageIds = List<String>.from(
      isEditing ? existingProduct.stageIds : <String>[],
    );

    XFile? pickedImageFile;
    Uint8List? localImageBytes;
    bool showUrlField = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            Future<void> pickImage(ImageSource source) async {
              try {
                final file = source == ImageSource.camera
                    ? await _storageService.pickImageFromCamera()
                    : await _storageService.pickImageFromGallery();
                if (file != null) {
                  final bytes = await file.readAsBytes();
                  setDialogState(() {
                    pickedImageFile = file;
                    localImageBytes = bytes;
                  });
                }
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to pick photo: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }

            void showPhotoSourceSheet() {
              showModalBottomSheet(
                context: dialogContext,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (sheetContext) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Select Product Photo',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt_outlined),
                          title: const Text('Take Photo with Camera'),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library_outlined),
                          title: const Text('Choose from Gallery'),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            pickImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            final bool hasPhoto = localImageBytes != null ||
                imageUrlController.text.trim().isNotEmpty;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note : Icons.add_box_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(isEditing ? 'Edit Product' : 'Create New Product'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        TextFormField(
                          controller: nameController,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Product Name *',
                            hintText:
                                'e.g., Heavy Duty Main Gate, Balcony Grill',
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a product name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText:
                                'Specifications, materials, or dimensions...',
                            prefixIcon:
                                const Icon(Icons.description_outlined),
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // PRODUCT PHOTO SECTION (Camera / Gallery / URL)
                        const Text(
                          'Product Photo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (hasPhoto)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(11),
                                  ),
                                  child: localImageBytes != null
                                      ? Image.memory(
                                          localImageBytes!,
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          imageUrlController.text.trim(),
                                          height: 140,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                            height: 140,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Text(
                                                'Failed to load image',
                                                style: TextStyle(
                                                    color: Colors.red),
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  color: Colors.grey[100],
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton.icon(
                                        onPressed: showPhotoSourceSheet,
                                        icon: const Icon(Icons.swap_horiz,
                                            size: 16),
                                        label: const Text('Change Photo'),
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red[600],
                                        ),
                                        onPressed: () {
                                          setDialogState(() {
                                            pickedImageFile = null;
                                            localImageBytes = null;
                                            imageUrlController.clear();
                                          });
                                        },
                                        icon: const Icon(Icons.delete_outline,
                                            size: 16),
                                        label: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () =>
                                            pickImage(ImageSource.camera),
                                        icon: const Icon(
                                            Icons.camera_alt_outlined),
                                        label: const Text('Take Photo'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () =>
                                            pickImage(ImageSource.gallery),
                                        icon: const Icon(
                                            Icons.photo_library_outlined),
                                        label: const Text('Gallery'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      showUrlField = !showUrlField;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(
                                      showUrlField
                                          ? 'Hide URL input'
                                          : 'Or enter photo URL directly',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        decoration:
                                            TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                if (showUrlField) ...[
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: imageUrlController,
                                    decoration: InputDecoration(
                                      labelText: 'Image Web URL',
                                      hintText: 'https://example.com/photo.jpg',
                                      prefixIcon:
                                          const Icon(Icons.link_outlined),
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Required Stages section
                        Row(
                          children: [
                            Icon(
                              Icons.account_tree_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Required Process Stages',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select the sequential stages required to build this product.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (availableStages.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.amber[300]!),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No stages defined yet. Please create stages in "Process Stages" first.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableStages.map((stage) {
                              final isSelected =
                                  selectedStageIds.contains(stage.id);
                              final orderIndex =
                                  selectedStageIds.indexOf(stage.id);

                              return FilterChip(
                                label: Text(
                                  isSelected
                                      ? '${orderIndex + 1}. ${stage.name}'
                                      : stage.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : null,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor:
                                    Theme.of(context).colorScheme.primary,
                                checkmarkColor: Colors.white,
                                onSelected: (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      selectedStageIds.add(stage.id);
                                    } else {
                                      selectedStageIds.remove(stage.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          if (selectedStageIds.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Build Flow Preview:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    selectedStageIds
                                        .map((id) {
                                          final match = availableStages
                                              .where((s) => s.id == id);
                                          return match.isNotEmpty
                                              ? match.first.name
                                              : id;
                                        })
                                        .toList()
                                        .asMap()
                                        .entries
                                        .map((e) => '${e.key + 1}. ${e.value}')
                                        .join('  ➔  '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            String? finalImageUrl =
                                imageUrlController.text.trim().isNotEmpty
                                    ? imageUrlController.text.trim()
                                    : null;

                            // If a new local image was picked from camera/gallery, upload to Firebase Storage
                            if (pickedImageFile != null) {
                              try {
                                final uploadedUrl = await _storageService
                                    .uploadProductImage(pickedImageFile!);
                                finalImageUrl = uploadedUrl;
                              } catch (uploadError) {
                                debugPrint(
                                    'Storage upload failed (will continue with existing/empty URL): $uploadError');
                              }
                            }

                            if (isEditing) {
                              await _productService.updateProduct(
                                id: existingProduct.id,
                                name: nameController.text,
                                description: descriptionController.text,
                                imageUrl: finalImageUrl,
                                stageIds: selectedStageIds,
                              );
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Product updated successfully'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              await _productService.addProduct(
                                name: nameController.text,
                                description: descriptionController.text,
                                imageUrl: finalImageUrl,
                                stageIds: selectedStageIds,
                              );
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Product created successfully'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to save product: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(isEditing ? Icons.save : Icons.add),
                  label: Text(
                    isSubmitting
                        ? 'Uploading & Saving...'
                        : (isEditing ? 'Save Changes' : 'Create Product'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteProduct(ProductModel product) {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Product'),
                ],
              ),
              content: Text(
                'Are you sure you want to delete "${product.name}"?\nThis action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() {
                            isDeleting = true;
                          });

                          try {
                            await _productService.deleteProduct(product.id);
                            messenger.showSnackBar(
                              SnackBar(
                                content:
                                    Text('Product "${product.name}" deleted'),
                                backgroundColor: Colors.red[700],
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() {
                                isDeleting = false;
                              });
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete product: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_forever),
                  label: Text(isDeleting ? 'Deleting...' : 'Delete'),
                ),
              ],
            );
          },
        );
      },
    );
  }  void _showFullImageDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProductOptionsModal({
    required BuildContext context,
    required ProductModel product,
    required List<StageModel> availableStages,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      child: product.imageUrl != null &&
                              product.imageUrl!.isNotEmpty
                          ? Image.network(
                              product.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Icon(
                                Icons.inventory_2_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.inventory_2_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'What would you like to do with this product?',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.edit_note,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Edit Product Details & Stages',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Update name, description, photo, or stages'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showAddOrEditProductDialog(
                      existingProduct: product,
                      availableStages: availableStages,
                    );
                  },
                ),
                if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.fullscreen, color: Colors.blue),
                    title: const Text('View Full Photo'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showFullImageDialog(
                        context,
                        product.imageUrl!,
                        product.name,
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Delete Product',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Permanently remove this product catalog'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmDeleteProduct(product);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StageModel>>(
      stream: _stageService.getStagesStream(),
      builder: (context, stagesSnapshot) {
        final availableStages = stagesSnapshot.data ?? [];
        final stageMap = {for (var s in availableStages) s.id: s.name};

        return StreamBuilder<List<ProductModel>>(
          stream: _productService.getProductsStream(),
          builder: (context, snapshot) {
            final products = snapshot.data ?? [];
            final hasProducts = products.isNotEmpty;

            return Scaffold(
              drawer: const AdminDrawer(currentScreen: AdminScreen.products),
              appBar: AppBar(
                title: const Text('Manage Products'),
              ),
              floatingActionButton: hasProducts
                  ? FloatingActionButton.extended(
                      onPressed: () => _showAddOrEditProductDialog(
                        availableStages: availableStages,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('New Product'),
                    )
                  : null,
              body: () {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  debugPrint('Error loading products: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'No Products Created Yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add fabrication products with descriptions, pictures, and required process stages.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showAddOrEditProductDialog(
                              availableStages: availableStages,
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Product'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 80, // Clearance for FAB
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showProductOptionsModal(
                          context: context,
                          product: product,
                          availableStages: availableStages,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Photo Thumbnail with zoom on tap
                                  GestureDetector(
                                    onTap: () {
                                      if (product.imageUrl != null &&
                                          product.imageUrl!.isNotEmpty) {
                                        _showFullImageDialog(
                                          context,
                                          product.imageUrl!,
                                          product.name,
                                        );
                                      }
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.08),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.2),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: product.imageUrl != null &&
                                                product.imageUrl!.isNotEmpty
                                            ? Image.network(
                                                product.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Icon(
                                                  Icons.inventory_2_outlined,
                                                  size: 36,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              )
                                            : Icon(
                                                Icons.inventory_2_outlined,
                                                size: 36,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Product Title & Description
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.description.isNotEmpty
                                              ? product.description
                                              : 'No description provided',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: product.description.isNotEmpty
                                                ? Colors.grey[700]
                                                : Colors.grey[400],
                                            fontStyle:
                                                product.description.isNotEmpty
                                                    ? FontStyle.normal
                                                    : FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Actions (Edit & Delete)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        tooltip: 'Edit Product',
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        onPressed: () =>
                                            _showAddOrEditProductDialog(
                                          existingProduct: product,
                                          availableStages: availableStages,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: 'Delete Product',
                                        color: Colors.red[400],
                                        onPressed: () =>
                                            _confirmDeleteProduct(product),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Stages Workflow Section
                              const Divider(height: 20),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.timeline,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Process Flow (${product.stageIds.length} stages):',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (product.stageIds.isEmpty)
                                Text(
                                  'No process stages assigned',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: product.stageIds
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final stepNumber = entry.key + 1;
                                    final stageId = entry.value;
                                    final stageName =
                                        stageMap[stageId] ?? stageId;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        '$stepNumber. $stageName',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }(),
            );
          },
        );
      },
    );
  }
}
