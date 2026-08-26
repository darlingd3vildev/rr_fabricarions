import 'package:flutter/material.dart';
import 'package:rr_fabrication/models/product_model.dart';
import 'package:rr_fabrication/models/stage_model.dart';
import 'package:rr_fabrication/services/product_service.dart';
import 'package:rr_fabrication/services/stage_service.dart';
import 'package:rr_fabrication/services/storage_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final ProductModel? initialProduct;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final StageService _stageService = StageService();
  final StorageService _storageService = StorageService();

  int _currentImageIndex = 0;
  late final PageController _pageController;
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showFullImageDialog(
      BuildContext context, String imageUrl, String title) {
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
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
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

  void _showAddPhotoSheet(ProductModel product) {
    final urlController = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Product Images',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload photos from device camera, gallery, or paste an image URL.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          try {
                            final file =
                                await _storageService.pickImageFromCamera();
                            if (file != null) {
                              setState(() => _isUploadingImages = true);
                              final url = await _storageService
                                  .uploadProductImage(file);
                              await _productService.addImagesToProduct(
                                  product.id, [url]);
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Photo uploaded successfully'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Camera upload failed: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isUploadingImages = false);
                            }
                          }
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Take Photo'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          try {
                            final files = await _storageService
                                .pickMultipleImagesFromGallery();
                            if (files.isNotEmpty) {
                              setState(() => _isUploadingImages = true);
                              final urls = await _storageService
                                  .uploadMultipleProductImages(files);
                              await _productService.addImagesToProduct(
                                  product.id, urls);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${urls.length} photo(s) uploaded successfully'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Gallery upload failed: $e'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isUploadingImages = false);
                            }
                          }
                        },
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Pick Gallery'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR VIA URL',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          hintText: 'https://example.com/image.jpg',
                          prefixIcon: const Icon(Icons.link_outlined),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final text = urlController.text.trim();
                        if (text.isEmpty) return;
                        Navigator.pop(sheetContext);
                        try {
                          await _productService
                              .addImagesToProduct(product.id, [text]);
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Photo URL added successfully'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to add photo URL: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteImage(ProductModel product, String imageUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Remove Photo'),
            ],
          ),
          content: const Text(
              'Are you sure you want to remove this photo from the product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _productService.removeImageFromProduct(
                      product.id, imageUrl);
                  if (_currentImageIndex >= product.imageUrls.length - 1 &&
                      _currentImageIndex > 0) {
                    setState(() {
                      _currentImageIndex = product.imageUrls.length - 2;
                    });
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Photo removed'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to remove photo: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  /// 1. SEPARATE DIALOG FOR EDITING PRODUCT NAME & DESCRIPTION
  void _showEditNameAndDescriptionDialog(ProductModel product) {
    final nameController = TextEditingController(text: product.name);
    final descriptionController =
        TextEditingController(text: product.description);
    final formKey = GlobalKey<FormState>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Edit Name & Description'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update the core details of this product. Process stages and photos will not be modified.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Product Name *',
                          hintText: 'e.g. Sliding Main Gate, Steel Railing',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Description / Specifications',
                          hintText: 'Materials, thickness, specs, notes...',
                          prefixIcon: const Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);

                          try {
                            await _productService.updateProductBasicDetails(
                              id: product.id,
                              name: nameController.text,
                              description: descriptionController.text,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Product details updated'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to update details: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(isSubmitting ? 'Saving...' : 'Save Details'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 2. SEPARATE DIALOG FOR EDITING PRODUCT DIMENSION VARIANTS & PRICING
  void _showEditProductVariantsDialog(ProductModel product) {
    List<ProductVariant> variants = List<ProductVariant>.from(product.variants);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            void showAddOrEditVariantSubDialog(
                {ProductVariant? existingVariant, int? index}) {
              final isEditingVariant = existingVariant != null;
              final dimensionsCtrl = TextEditingController(
                  text: isEditingVariant ? existingVariant.dimensions : '');
              final priceCtrl = TextEditingController(
                  text: isEditingVariant
                      ? existingVariant.price.toStringAsFixed(0)
                      : '');
              final unitCtrl = TextEditingController(
                  text: isEditingVariant ? (existingVariant.priceUnit ?? '') : '');
              final materialCtrl = TextEditingController(
                  text: isEditingVariant ? (existingVariant.materialSpec ?? '') : '');
              final descCtrl = TextEditingController(
                  text: isEditingVariant ? (existingVariant.description ?? '') : '');
              final subFormKey = GlobalKey<FormState>();

              showDialog(
                context: dialogContext,
                builder: (subContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: [
                        Icon(
                            isEditingVariant
                                ? Icons.edit_note
                                : Icons.add_circle_outline,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(isEditingVariant
                            ? 'Edit Variant'
                            : 'Add Dimension Variant'),
                      ],
                    ),
                    content: SizedBox(
                      width: 440,
                      child: Form(
                        key: subFormKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: dimensionsCtrl,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  labelText: 'Dimensions / Size *',
                                  hintText: 'e.g. 10ft x 12ft, Standard 6x4 ft',
                                  prefixIcon: Icon(Icons.straighten),
                                ),
                                validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      controller: priceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'Price (₹) *',
                                        hintText: 'e.g. 25000',
                                        prefixIcon: Icon(Icons.currency_rupee),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty) {
                                          return 'Required';
                                        }
                                        if (double.tryParse(v.trim()) == null) {
                                          return 'Enter a valid number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: unitCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Unit',
                                        hintText: 'per piece',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: materialCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Material Spec / Gauge',
                                  hintText:
                                      'e.g. 16 Gauge MS, Powder Coated',
                                  prefixIcon: Icon(Icons.layers_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: descCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Notes / Specifications',
                                  hintText: 'Optional notes for this variant...',
                                  prefixIcon: Icon(Icons.notes_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(subContext),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (!subFormKey.currentState!.validate()) return;
                          final parsedPrice =
                              double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                          final newVariant = ProductVariant(
                            id: isEditingVariant
                                ? existingVariant.id
                                : DateTime.now().millisecondsSinceEpoch.toString(),
                            dimensions: dimensionsCtrl.text.trim(),
                            price: parsedPrice,
                            priceUnit: unitCtrl.text.trim().isNotEmpty
                                ? unitCtrl.text.trim()
                                : null,
                            materialSpec: materialCtrl.text.trim().isNotEmpty
                                ? materialCtrl.text.trim()
                                : null,
                            description: descCtrl.text.trim().isNotEmpty
                                ? descCtrl.text.trim()
                                : null,
                          );

                          setDialogState(() {
                            if (isEditingVariant && index != null) {
                              variants[index] = newVariant;
                            } else {
                              variants.add(newVariant);
                            }
                          });

                          Navigator.pop(subContext);
                        },
                        child: Text(isEditingVariant ? 'Update' : 'Add'),
                      ),
                    ],
                  );
                },
              );
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.price_change_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Text('Manage Dimension Pricing'),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configure multiple dimension variants vs. cost for "${product.name}".',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Variants (${variants.length})',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                          onPressed: () => showAddOrEditVariantSubDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Dimension'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (variants.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'No dimension pricing variants configured.\nTap "Add Dimension" above to create sizing options.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: variants.length,
                          itemBuilder: (context, idx) {
                            final v = variants[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              child: ListTile(
                                dense: true,
                                title: Text(
                                  v.dimensions,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                subtitle: Text(
                                  '₹${v.price.toStringAsFixed(0)} ${v.priceUnit ?? ''}${v.materialSpec != null && v.materialSpec!.isNotEmpty ? ' • ${v.materialSpec}' : ''}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700]),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18),
                                      onPressed: () =>
                                          showAddOrEditVariantSubDialog(
                                              existingVariant: v,
                                              index: idx),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: Colors.red),
                                      onPressed: () {
                                        setDialogState(() {
                                          variants.removeAt(idx);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _productService.updateProductVariants(
                              id: product.id,
                              variants: variants,
                            );
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Product variants & pricing saved'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to save variants: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(isSubmitting ? 'Saving...' : 'Save Pricing'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 3. SEPARATE DIALOG FOR EDITING PRODUCT STAGES PIPELINE
  void _showEditProductStagesDialog({
    required ProductModel product,
    required List<StageModel> availableStages,
  }) {
    List<String> selectedStageIds = List<String>.from(product.stageIds);
    final messenger = ScaffoldMessenger.of(context);
    final stageMap = {for (var s in availableStages) s.id: s};

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            void moveStage(int oldIndex, int newIndex) {
              if (newIndex < 0 || newIndex >= selectedStageIds.length) return;
              setDialogState(() {
                final item = selectedStageIds.removeAt(oldIndex);
                selectedStageIds.insert(newIndex, item);
              });
            }

            void removeStage(int index) {
              setDialogState(() {
                selectedStageIds.removeAt(index);
              });
            }

            void addStage(String stageId) {
              if (!selectedStageIds.contains(stageId)) {
                setDialogState(() {
                  selectedStageIds.add(stageId);
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Edit Process Stages'),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add, remove, or reorder the sequential fabrication steps required to manufacture this product.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 14),

                      // Current Stages in Order
                      const Text(
                        'Sequential Stage Pipeline:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (selectedStageIds.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber[300]!),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No stages in pipeline. Tap on available stages below to add them.',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: selectedStageIds.length,
                          itemBuilder: (context, index) {
                            final stageId = selectedStageIds[index];
                            final stage = stageMap[stageId];
                            final stageName = stage?.name ?? stageId;
                            final isFirst = index == 0;
                            final isLast =
                                index == selectedStageIds.length - 1;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.15),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  stageName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_upward,
                                          size: 16),
                                      onPressed: isFirst
                                          ? null
                                          : () => moveStage(index, index - 1),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.arrow_downward,
                                          size: 16),
                                      onPressed: isLast
                                          ? null
                                          : () => moveStage(index, index + 1),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 18, color: Colors.red),
                                      onPressed: () => removeStage(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 16),

                      // Add from available stages
                      const Text(
                        'Available Stages (Tap to Add):',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      if (availableStages.isEmpty)
                        const Text(
                          'No predefined stages found. Create stages in "Process Stages" first.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: availableStages.map((stage) {
                            final isAlreadyAdded =
                                selectedStageIds.contains(stage.id);

                            return ActionChip(
                              avatar: Icon(
                                isAlreadyAdded ? Icons.check : Icons.add,
                                size: 14,
                                color: isAlreadyAdded ? Colors.green : null,
                              ),
                              label: Text(
                                stage.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isAlreadyAdded
                                      ? Colors.grey[600]
                                      : null,
                                ),
                              ),
                              backgroundColor: isAlreadyAdded
                                  ? Colors.grey[100]
                                  : null,
                              onPressed: isAlreadyAdded
                                  ? null
                                  : () => addStage(stage.id),
                            );
                          }).toList(),
                        ),

                      if (selectedStageIds.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
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
                                'Flow Preview:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedStageIds
                                    .map((id) => stageMap[id]?.name ?? id)
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((e) => '${e.key + 1}. ${e.value}')
                                    .join('  ➔  '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);

                          try {
                            await _productService.updateProductStages(
                              id: product.id,
                              stageIds: selectedStageIds,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Product stages updated'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setDialogState(() => isSubmitting = false);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content:
                                    Text('Failed to update stages: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                      isSubmitting ? 'Saving Stages...' : 'Save Stage Pipeline'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteProduct(ProductModel product) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _productService.deleteProduct(product.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Product "${product.name}" deleted'),
                        backgroundColor: Colors.red[700],
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete product: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete'),
            ),
          ],
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
        final stageMap = {for (var s in availableStages) s.id: s};

        return StreamBuilder<ProductModel>(
          stream: _productService.getProductStream(widget.productId),
          initialData: widget.initialProduct,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Product Details')),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError && snapshot.data == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Product Details')),
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                          'Product not found or error loading details: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final product = snapshot.data;
            if (product == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Product Details')),
                body: const Center(child: Text('Product not found')),
              );
            }

            final images = product.imageUrls;

            return Scaffold(
              appBar: AppBar(
                title: Text(product.name),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MULTI-IMAGE GALLERY / CAROUSEL
                    if (images.isNotEmpty) ...[
                      Stack(
                        children: [
                          SizedBox(
                            height: 280,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final imgUrl = images[index];
                                return GestureDetector(
                                  onTap: () => _showFullImageDialog(
                                    context,
                                    imgUrl,
                                    '${product.name} (${index + 1}/${images.length})',
                                  ),
                                  child: Container(
                                    color: Colors.black,
                                    child: Image.network(
                                      imgUrl,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Icon(Icons.broken_image,
                                              size: 48, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Count badge top right
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_currentImageIndex + 1} / ${images.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          // Zoom hint top left
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.fullscreen,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                          // Remove photo button
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.black.withValues(alpha: 0.65),
                                foregroundColor: Colors.red[300],
                              ),
                              icon: const Icon(Icons.delete_outline, size: 20),
                              tooltip: 'Remove Current Photo',
                              onPressed: () => _confirmDeleteImage(
                                product,
                                images[_currentImageIndex.clamp(
                                    0, images.length - 1)],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Thumbnail Strip & Add button
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        color: Colors.grey[100],
                        child: Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: images.length,
                                  itemBuilder: (context, index) {
                                    final isSelected =
                                        index == _currentImageIndex;
                                    return GestureDetector(
                                      onTap: () {
                                        _pageController.animateToPage(
                                          index,
                                          duration: const Duration(
                                              milliseconds: 300),
                                          curve: Curves.easeInOut,
                                        );
                                      },
                                      child: Container(
                                        width: 54,
                                        height: 54,
                                        margin:
                                            const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Colors.grey[300]!,
                                            width: isSelected ? 2.5 : 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.network(
                                            images[index],
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(Icons.image,
                                                    size: 20),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              onPressed: () => _showAddPhotoSheet(product),
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined),
                              tooltip: 'Add More Photos',
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // No images placeholder
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 36, horizontal: 20),
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.05),
                        child: Column(
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No photos added yet',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add photos from camera, gallery, or URL',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showAddPhotoSheet(product),
                              icon: const Icon(Icons.add_a_photo_outlined,
                                  size: 18),
                              label: const Text('Add Product Photos'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (_isUploadingImages)
                      const LinearProgressIndicator(minHeight: 3),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. PRODUCT INFORMATION CARD (With dedicated Edit Name/Description button)
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${product.stageIds.length} Stages',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    product.description.isNotEmpty
                                        ? product.description
                                        : 'No detailed description provided for this product.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: product.description.isNotEmpty
                                          ? Colors.grey[800]
                                          : Colors.grey[500],
                                      height: 1.4,
                                      fontStyle:
                                          product.description.isNotEmpty
                                              ? FontStyle.normal
                                              : FontStyle.italic,
                                    ),
                                  ),
                                  if (product.createdAt != null) ...[
                                    const Divider(height: 24),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_outlined,
                                            size: 14,
                                            color: Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Created: ${product.createdAt!.day}/${product.createdAt!.month}/${product.createdAt!.year}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                        const Spacer(),
                                        Icon(Icons.photo_library_outlined,
                                            size: 14,
                                            color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${images.length} photos',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const Divider(height: 20),
                                  // Dedicated Edit Name & Description Button
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _showEditNameAndDescriptionDialog(
                                                product),
                                        icon: const Icon(
                                            Icons.edit_note_outlined,
                                            size: 18),
                                        label: const Text(
                                            'Edit Name & Description'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 2. DIMENSION VARIANTS & PRICING CARD (With dedicated Manage Pricing button)
                          Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.price_change_outlined,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Dimension Variants & Cost',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                        onPressed: () =>
                                            _showEditProductVariantsDialog(
                                                product),
                                        icon: const Icon(
                                            Icons.tune,
                                            size: 16),
                                        label: const Text('Manage Pricing'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Range: ${product.priceRangeString}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (product.variants.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                            color: Colors.grey[200]!),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline,
                                              size: 18,
                                              color: Colors.grey[600]),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'No dimension pricing variants configured. Tap "Manage Pricing" to add sizing options and costs.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: product.variants.length,
                                      itemBuilder: (context, index) {
                                        final v = product.variants[index];
                                        return Container(
                                          margin: const EdgeInsets.only(
                                              bottom: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: const Color(
                                                    0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      v.dimensions,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    if (v.materialSpec !=
                                                            null &&
                                                        v.materialSpec!
                                                            .isNotEmpty)
                                                      Text(
                                                        v.materialSpec!,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors
                                                              .grey[600],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '₹${v.price.toStringAsFixed(0)} ${v.priceUnit ?? ''}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 3. FABRICATION PROCESS STAGES (With dedicated Manage Stages button)
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.account_tree_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Fabrication Process Stages',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                onPressed: () =>
                                    _showEditProductStagesDialog(
                                  product: product,
                                  availableStages: availableStages,
                                ),
                                icon: const Icon(Icons.tune, size: 16),
                                label: const Text('Edit Stages'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sequential build steps executed for orders of this product:',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 14),

                          if (product.stageIds.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: Colors.orange),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'No stages assigned. Tap "Edit Stages" above to define sequential build steps.',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.amber[900]),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: product.stageIds.length,
                              itemBuilder: (context, index) {
                                final stageId = product.stageIds[index];
                                final stage = stageMap[stageId];
                                final stageName = stage?.name ?? stageId;
                                final stageDesc = stage?.description ?? '';
                                final isLast =
                                    index == product.stageIds.length - 1;

                                return Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Step timeline column
                                    Column(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        if (!isLast)
                                          Container(
                                            width: 2,
                                            height: 48,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.3),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    // Step card
                                    Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(
                                            bottom: isLast ? 0 : 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.grey[200]!,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.02),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              stageName,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (stageDesc.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                stageDesc,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                          const SizedBox(height: 32),

                          // 3. DELETE PRODUCT BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red[700],
                                side: BorderSide(color: Colors.red[300]!),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () =>
                                  _confirmDeleteProduct(product),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete Product'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
