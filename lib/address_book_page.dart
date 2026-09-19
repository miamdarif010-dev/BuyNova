import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddressBookPage extends StatelessWidget {
  const AddressBookPage({super.key});

  // =========================================================
  // ADDRESS FORM
  // =========================================================

  void _showAddressForm(
    BuildContext context, {
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) {
    final data = document?.data();

    final nameController = TextEditingController(
      text: data?['name']?.toString() ?? '',
    );

    final phoneController = TextEditingController(
      text: data?['phone']?.toString() ?? '',
    );

    final addressController = TextEditingController(
      text: data?['address']?.toString() ?? '',
    );

    bool isDefault = data?['isDefault'] == true;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> saveAddress() async {
              if (saving) return;

              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final address = addressController.text.trim();

              if (name.isEmpty ||
                  phone.isEmpty ||
                  address.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please fill in all address fields.',
                    ),
                  ),
                );
                return;
              }

              final user =
                  FirebaseAuth.instance.currentUser;

              if (user == null) return;

              setState(() {
                saving = true;
              });

              try {
                final firestore =
                    FirebaseFirestore.instance;

                final addressCollection = firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('addresses');

                final batch = firestore.batch();

                // ------------------------------------------------
                // IF DEFAULT, REMOVE DEFAULT FROM OTHER ADDRESSES
                // ------------------------------------------------

                if (isDefault) {
                  final existing =
                      await addressCollection.get();

                  for (final item in existing.docs) {
                    if (document == null ||
                        item.id != document.id) {
                      batch.update(
                        item.reference,
                        {
                          'isDefault': false,
                          'updatedAt':
                              FieldValue.serverTimestamp(),
                        },
                      );
                    }
                  }
                }

                // ------------------------------------------------
                // SAVE / UPDATE
                // ------------------------------------------------

                final addressRef = document != null
                    ? addressCollection.doc(document.id)
                    : addressCollection.doc();

                final addressData = <String, dynamic>{
                  'name': name,
                  'phone': phone,
                  'address': address,
                  'isDefault': isDefault,
                  'updatedAt':
                      FieldValue.serverTimestamp(),
                };

                if (document == null) {
                  addressData['createdAt'] =
                      FieldValue.serverTimestamp();
                }

                batch.set(
                  addressRef,
                  addressData,
                  SetOptions(merge: true),
                );

                await batch.commit();

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      document == null
                          ? 'Address added successfully.'
                          : 'Address updated successfully.',
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;

                setState(() {
                  saving = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Could not save address.\n$e',
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              title: Text(
                document == null
                    ? 'Add New Address'
                    : 'Edit Address',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization:
                          TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon:
                            Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType:
                          TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon:
                            Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      maxLines: 3,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Full Address',
                        prefixIcon:
                            Icon(Icons.location_on_outlined),
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isDefault,
                      onChanged: saving
                          ? null
                          : (value) {
                              setState(() {
                                isDefault =
                                    value ?? false;
                              });
                            },
                      title: const Text(
                        'Set as default address',
                      ),
                      controlAffinity:
                          ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : saveAddress,
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // DELETE ADDRESS
  // =========================================================

  Future<void> _deleteAddress(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>>
        document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Address?',
          ),
          content: const Text(
            'Are you sure you want to delete this address?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(document.id)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Address deleted successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete address.\n$e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // SET DEFAULT
  // =========================================================

  Future<void> _setDefaultAddress(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>>
        selectedDocument,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final firestore =
          FirebaseFirestore.instance;

      final collection = firestore
          .collection('users')
          .doc(user.uid)
          .collection('addresses');

      final snapshot = await collection.get();

      final batch = firestore.batch();

      for (final document in snapshot.docs) {
        batch.update(
          document.reference,
          {
            'isDefault':
                document.id == selectedDocument.id,
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Default address updated.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update default address.\n$e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // ADDRESS CARD
  // =========================================================

  Widget _addressCard(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>>
        document,
  ) {
    final data = document.data() ?? {};

    final name =
        data['name']?.toString() ?? '';

    final phone =
        data['phone']?.toString() ?? '';

    final address =
        data['address']?.toString() ?? '';

    final isDefault =
        data['isDefault'] == true;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor:
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.10),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.isEmpty
                                  ? 'Address'
                                  : name,
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isDefault)
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: Colors.green
                                    .withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  color:
                                      Colors.green,
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          phone,
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Text(
              address,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 14),

            const Divider(
              height: 1,
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                if (!isDefault)
                  TextButton.icon(
                    onPressed: () {
                      _setDefaultAddress(
                        context,
                        document,
                      );
                    },
                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: const Text(
                      'Set Default',
                    ),
                  ),

                const Spacer(),

                IconButton(
                  tooltip: 'Edit',
                  onPressed: () {
                    _showAddressForm(
                      context,
                      document: document,
                    );
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                ),

                IconButton(
                  tooltip: 'Delete',
                  onPressed: () {
                    _deleteAddress(
                      context,
                      document,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Address Book',
          ),
        ),
        body: const Center(
          child: Text(
            'Please login to manage your addresses.',
          ),
        ),
      );
    }

    final addressStream =
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('addresses')
            .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Address Book',
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () {
          _showAddressForm(context);
        },
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Address',
        ),
      ),
      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: addressStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),
                child: Text(
                  'Unable to load addresses.\n\n'
                  '${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final documents =
              snapshot.data?.docs.toList() ?? [];

          documents.sort((a, b) {
            final aDefault =
                a.data()['isDefault'] == true;

            final bDefault =
                b.data()['isDefault'] == true;

            if (aDefault && !bDefault) {
              return -1;
            }

            if (!aDefault && bDefault) {
              return 1;
            }

            return 0;
          });

          if (documents.isEmpty) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 75,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'No Addresses Yet',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add your delivery address '
                      'for faster checkout.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: () {
                        _showAddressForm(
                          context,
                        );
                      },
                      icon: const Icon(
                        Icons.add,
                      ),
                      label: const Text(
                        'Add Your First Address',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              100,
            ),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              return _addressCard(
                context,
                documents[index],
              );
            },
          );
        },
      ),
    );
  }
}
