import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rr_fabrication/models/product_model.dart';
import 'package:rr_fabrication/models/stage_model.dart';
import 'package:rr_fabrication/screens/admin/admin_drawer.dart';
import 'package:rr_fabrication/screens/admin/product_detail_screen.dart';
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
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    // Selected stage IDs for this product (retaining order)
    final selectedStageIds = List<String>.from(
      isEditing ? existingProduct.stageIds : <String>[],
    );

    final List<String> currentImageUrls = List<String>.from(
      isEditing ? existingProduct.imageUrls : <String>[],
    );
    final List<XFile> newPickedFiles = [];
    final List<Uint8List> newPickedBytes = [];
    final urlInputController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            Future<void> pickPhotos(ImageSource source) async {
              try {
                if (source == ImageSource.camera) {
                  final file = await _storageService.pickImageFromCamera();
                  if (file != null) {
                    final bytes = await file.readAsBytes();
                    setDialogState(() {
                      newPickedFiles.add(file);
                      newPickedBytes.add(bytes);
                    });
                  }
                } else {
                  final files = await _storageService.pickMultipleImagesFromGallery();
                  for (final f in files) {
                    final b = await f.readAsBytes();
                    newPickedFiles.add(f);
                    newPickedBytes.add(b);
                  }
                  setDialogState(() {});
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
                width: 500,
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
                        const SizedBox(height: 20),

                        // PRODUCT PHOTOS SECTION
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Product Images',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${currentImageUrls.length + newPickedBytes.length} added',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Image Preview Strip
                        if (currentImageUrls.isNotEmpty || newPickedBytes.isNotEmpty)
                          SizedBox(
                            height: 80,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                ...currentImageUrls.map((url) {
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[300]!),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            url,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(Icons.broken_image),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: () {
                                            setDialogState(() {
                                              currentImageUrls.remove(url);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close,
                                                size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                                ...newPickedBytes.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final bytes = entry.value;
                                  return Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green[400]!),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(bytes, fit: BoxFit.cover),
                                        ),
                                      ),
                                      Positioned(
                                        top: 2,
                                        right: 10,
                                        child: GestureDetector(
                                          onTap: () {
                                            setDialogState(() {
                                              newPickedBytes.removeAt(idx);
                                              newPickedFiles.removeAt(idx);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close,
                                                size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pickPhotos(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt_outlined, size: 16),
                                label: const Text('Camera'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pickPhotos(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined, size: 16),
                                label: const Text('Gallery'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: urlInputController,
                                decoration: InputDecoration(
                                  hintText: 'Or enter image URL...',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton.filledTonal(
                              onPressed: () {
                                final text = urlInputController.text.trim();
                                if (text.isNotEmpty) {
                                  setDialogState(() {
                                    currentImageUrls.add(text);
                                    urlInputController.clear();
                                  });
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                            ),
                          ],
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
                            final uploadedUrls = await _storageService
                                .uploadMultipleProductImages(newPickedFiles);
                            final allFinalUrls = [
                              ...currentImageUrls,
                              ...uploadedUrls,
                            ];

                            if (isEditing) {
                              await _productService.updateProduct(
                                id: existingProduct.id,
                                name: nameController.text,
                                description: descriptionController.text,
                                imageUrls: allFinalUrls,
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
                                imageUrls: allFinalUrls,
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
                        ? 'Saving Product...'
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
                            'Add fabrication products with descriptions, multiple photos, and required process stages.',
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
                    final firstImageUrl = product.imageUrl;
                    final photoCount = product.imageUrls.length;

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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                productId: product.id,
                                initialProduct: product,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Photo Thumbnail with photo count badge
                                  Stack(
                                    children: [
                                      ClipRRect(
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
                                          child: firstImageUrl != null &&
                                                  firstImageUrl.isNotEmpty
                                              ? Image.network(
                                                  firstImageUrl,
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
                                      if (photoCount > 1)
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.7),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.photo_library,
                                                    size: 10, color: Colors.white),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '$photoCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
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

                                  // Chevron for navigation indicator
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey[400],
                                    ),
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
