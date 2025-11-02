import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/medicine_model.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/util/helpers.dart';
import '../data/pillbox_model.dart';

class PillBoxNotifier extends StateNotifier<IPillBox> {
  static String _duplicateNameError(String name) => 
    'A medicine with the name "$name" already exists. '
    'Medicine names must be unique to ensure proper lookups.';
  
  PillBoxNotifier() : super(PillBox()) {
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    final loaded = await HiveService.loadPillBox();
    devPrint('[PillBoxNotifier._loadFromHive] Setting state: $loaded');
    if (loaded.isNotEmpty) {
      // Use proper deserialization with the extension methods
      final deserializedStock = loaded.map((item) => 
        MedicineInventorySerialization.fromJson(Map<String, dynamic>.from(item))).toList();
      state = PillBox.populate(deserializedStock);
    } else {
      state = PillBox();
    }
  }

  void addMedicine(Medicine medicine, int quantity) {
    // Validate that the medicine name doesn't already exist (case-insensitive)
    final duplicateExists = state.pillStock.any(
      (item) => item.medicine.name.toLowerCase() == medicine.name.toLowerCase(),
    );
    
    if (duplicateExists) {
      throw ArgumentError(_duplicateNameError(medicine.name));
    }
    
    final newStock = [...state.pillStock, MedicineInventory(medicine: medicine, quantity: quantity)];
    state = PillBox.populate(newStock);
    devPrint('[PillBoxNotifier.addMedicine] New state: $newStock');
    HiveService.savePillBox(state.pillStock);
  }

  void removeMedicine(Medicine medicine) {
    final newStock = state.pillStock.where((item) => item.medicine.name != medicine.name).toList();
    state = PillBox.populate(newStock);
    devPrint('[PillBoxNotifier.removeMedicine] New state: $newStock');
    HiveService.savePillBox(state.pillStock);
  }

  void updateMedicineQuantity(MedicineInventory inventory, int newQuantity) {
    final newStock = state.pillStock.map((item) {
      if (item.medicine.name == inventory.medicine.name) {
        return MedicineInventory(medicine: item.medicine, quantity: newQuantity);
      }
      return item;
    }).toList();
    state = PillBox.populate(newStock);
    devPrint('[PillBoxNotifier.updateMedicineQuantity] New state: $newStock');
    HiveService.savePillBox(state.pillStock);
  }

  /// Updates a medicine. Returns true if successful, false if duplicate name detected.
  bool updateMedicine(MedicineInventory inventory, String newName, String newType, String newColor) {
    // Validate that the new name doesn't conflict with existing medicines
    // Only check for duplicates if the name is actually being changed
    if (newName.toLowerCase() != inventory.medicine.name.toLowerCase()) {
      final duplicateExists = state.pillStock.any(
        (item) => item.medicine.name.toLowerCase() == newName.toLowerCase(),
      );
      
      // If a medicine with the new name already exists, fail gracefully
      // (We know it's not the current medicine since we checked newName != inventory.medicine.name above)
      if (duplicateExists) {
        devPrint('[PillBoxNotifier.updateMedicine] Duplicate medicine name detected: "$newName". Update cancelled to maintain unique names.');
        return false; // Return false to indicate failure without changing state or persisting
      }
    }
    
    final newStock = state.pillStock.map((item) {
      if (item.medicine.name == inventory.medicine.name) {
        // Create new Medicine with updated properties
        final updatedMedicine = Medicine(
          name: newName,
          type: newType,
          color: newColor,
        );
        // Preserve the existing specification
        updatedMedicine.addSpecification(item.medicine.specs);
        
        return MedicineInventory(medicine: updatedMedicine, quantity: item.quantity);
      }
      return item;
    }).toList();
    state = PillBox.populate(newStock);
    devPrint('[PillBoxNotifier.updateMedicine] Updated medicine: $newName, $newType, $newColor');
    HiveService.savePillBox(state.pillStock);
    return true; // Return true to indicate success
  }

  void updatePillbox(List<MedicineInventory> pillStock) {
    state = PillBox.populate(pillStock);
    devPrint('[PillBoxNotifier.updatePillbox] New state: $pillStock');
    HiveService.savePillBox(state.pillStock);
  }

  /// Decrement quantity for a medicine by name
  /// Returns true if medication was found and quantity was decremented
  bool decrementMedicineQuantity(String medicineName, {int amount = 1}) {
    final matchingItems = state.pillStock.where(
      (item) => item.medicine.name == medicineName,
    ).toList();
    
    if (matchingItems.isEmpty) {
      devPrint('[PillBoxNotifier] Medicine $medicineName not found in pillbox');
      return false;
    }
    
    final medicineInventory = matchingItems.first;
    
    if (medicineInventory.quantity >= amount) {
      final newQuantity = medicineInventory.quantity - amount;
      updateMedicineQuantity(medicineInventory, newQuantity);
      devPrint('[PillBoxNotifier] Decremented $medicineName by $amount. New quantity: $newQuantity');
      return true;
    } else {
      devPrint('[PillBoxNotifier] Cannot decrement $medicineName: insufficient quantity (${medicineInventory.quantity})');
      return false;
    }
  }
}

final pillBoxProvider = StateNotifierProvider<PillBoxNotifier, IPillBox>((ref) => PillBoxNotifier());