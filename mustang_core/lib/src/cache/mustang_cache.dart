import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:mustang_core/src/store/mustang_store.dart';

/// [MustangCache] provides utility methods to save/lookup instances
/// of any type.
///
/// Only one instance of cache store exists for an App.
class MustangCache {
  /// Hive Box Name to cache the model data
  static String cacheName = '';

  static void configCache(String cacheName) async {
    MustangCache.cacheName = cacheName;
  }

  /// Creates [storeLocation] in the file system to save serialized objects
  /// [storeLocation] is optional for Web
  static Future<void> initCache(String? storeLocation) async {
    if (storeLocation != null) {
      Hive.init(storeLocation);
    }
    await Hive.openLazyBox(cacheName);
  }

  static Future<Map<String, dynamic>?> getObject<T>(String key,
      String modelKey,) async {
    LazyBox lazyBox = Hive.lazyBox(cacheName);
    Map<String, String> cacheData =
        (await lazyBox.get(key))?.cast<String, String>() ?? {};
    return cacheData[modelKey] == null ? null : jsonDecode(
        cacheData[modelKey]!);
  }

  /// Writes serialized object to a file
  static Future<void> addObject(String key,
      String modelKey,
      String modelValue,) async {
    LazyBox lazyBox = Hive.lazyBox(cacheName);
    Map<String, String> value;

    if (lazyBox.isOpen) {
      value = (await lazyBox.get(key))?.cast<String, String>() ?? {};
      value.update(
        modelKey,
            (_) => modelValue,
        ifAbsent: () => modelValue,
      );
      await lazyBox.put(key, value);
    }
  }

  /// Deserializes the previously serialized string into an object and
  /// - updates MustangStore
  /// - updates Persistence store
  static Future<void> restoreObjects(String key,
      void Function(
          void Function<T>(T t) update,
          String modelName,
          String jsonStr,
          )
      callback,) async {
    LazyBox lazyBox = Hive.lazyBox(cacheName);
    if (lazyBox.isOpen) {
      Map<String, String> cacheData =
          (await lazyBox.get(key))?.cast<String, String>() ?? {};
      for (String modelKey in cacheData.keys) {
        MustangStore.persistObject(modelKey, cacheData[modelKey]!);
        callback(MustangStore.update, modelKey, cacheData[modelKey]!);
      }
    }
  }

  static Future<void> deleteObjects(String key) async {
    LazyBox lazyBox = Hive.lazyBox(cacheName);
    if (lazyBox.isOpen) {
      await lazyBox.delete(key);
    }
  }

  static bool itemExists(String key) {
    LazyBox lazyBox = Hive.lazyBox(cacheName);
    return ((lazyBox.isOpen) && lazyBox.containsKey(key));
  }
}
