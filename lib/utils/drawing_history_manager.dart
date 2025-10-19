import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DrawingHistoryManager {
  static const String _favoritesKey = 'drawing_favorites';
  static const String _recentKey = 'drawing_recent';
  static const String _drawingsKey = 'saved_drawings';
  static const String _metadataKey = 'drawing_metadata';

  // Favorites Management
  static Future<void> addToFavorites(String drawingId, Map<String, dynamic> metadata) async {
    final prefs = await SharedPreferences.getInstance();

    // Get current favorites
    final favoritesJson = prefs.getString(_favoritesKey);
    final Map<String, dynamic> favorites = favoritesJson != null
        ? Map<String, dynamic>.from(json.decode(favoritesJson))
        : {};

    // Add to favorites
    favorites[drawingId] = {
      ...metadata,
      'favoritedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_favoritesKey, json.encode(favorites));
    await _updateDrawingMetadata(drawingId, {'isFavorite': true});
  }

  static Future<void> removeFromFavorites(String drawingId) async {
    final prefs = await SharedPreferences.getInstance();

    final favoritesJson = prefs.getString(_favoritesKey);
    if (favoritesJson != null) {
      final Map<String, dynamic> favorites = Map<String, dynamic>.from(json.decode(favoritesJson));
      favorites.remove(drawingId);
      await prefs.setString(_favoritesKey, json.encode(favorites));
    }

    await _updateDrawingMetadata(drawingId, {'isFavorite': false});
  }

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);

    if (favoritesJson != null) {
      final Map<String, dynamic> favorites = Map<String, dynamic>.from(json.decode(favoritesJson));
      return favorites.entries.map((entry) {
        return {
          'id': entry.key,
          ...entry.value,
        };
      }).toList();
    }

    return [];
  }

  // Recent Drawings Management
  static Future<void> addToRecent(String drawingId, Map<String, dynamic> metadata) async {
    final prefs = await SharedPreferences.getInstance();

    // Get current recent drawings
    final recentJson = prefs.getString(_recentKey);
    final List<dynamic> recent = recentJson != null
        ? List<dynamic>.from(json.decode(recentJson))
        : [];

    // Remove if already exists
    recent.removeWhere((item) => item is Map && item['id'] == drawingId);

    // Add to beginning with metadata
    recent.insert(0, {
      'id': drawingId,
      ...metadata,
      'accessedAt': DateTime.now().toIso8601String(),
    });

    // Keep only last 50 recent items
    if (recent.length > 50) {
      recent.removeLast();
    }

    await prefs.setString(_recentKey, json.encode(recent));
    await _updateDrawingMetadata(drawingId, {
      'lastAccessed': DateTime.now().toIso8601String(),
      'accessCount': await getAccessCount(drawingId) + 1,
    });
  }

  static Future<List<Map<String, dynamic>>> getRecent({int limit = 20}) async {
    final prefs = await SharedPreferences.getInstance();
    final recentJson = prefs.getString(_recentKey);

    if (recentJson != null) {
      final List<dynamic> recent = List<dynamic>.from(json.decode(recentJson));
      return recent.take(limit).map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
    }

    return [];
  }

  // Drawing Metadata Management
  static Future<void> _updateDrawingMetadata(String drawingId, Map<String, dynamic> updates) async {
    final prefs = await SharedPreferences.getInstance();

    final metadataJson = prefs.getString(_metadataKey);
    final Map<String, dynamic> metadata = metadataJson != null
        ? Map<String, dynamic>.from(json.decode(metadataJson))
        : {};

    if (!metadata.containsKey(drawingId)) {
      metadata[drawingId] = {
        'createdAt': DateTime.now().toIso8601String(),
        'accessCount': 0,
        'isFavorite': false,
      };
    }

    metadata[drawingId] = {
      ...metadata[drawingId],
      ...updates,
    };

    await prefs.setString(_metadataKey, json.encode(metadata));
  }

  static Future<Map<String, dynamic>?> getDrawingMetadata(String drawingId) async {
    final prefs = await SharedPreferences.getInstance();
    final metadataJson = prefs.getString(_metadataKey);

    if (metadataJson != null) {
      final Map<String, dynamic> metadata = Map<String, dynamic>.from(json.decode(metadataJson));
      return metadata[drawingId];
    }

    return null;
  }

  static Future<int> getAccessCount(String drawingId) async {
    final metadata = await getDrawingMetadata(drawingId);
    return metadata?['accessCount'] ?? 0;
  }

  static Future<bool> isFavorite(String drawingId) async {
    final metadata = await getDrawingMetadata(drawingId);
    return metadata?['isFavorite'] ?? false;
  }

  // Search and Filter
  static Future<List<Map<String, dynamic>>> searchDrawings(String query) async {
    final recent = await getRecent(limit: 1000);
    final favorites = await getFavorites();

    final allDrawings = {...{
      for (var drawing in recent) drawing['id']: drawing
    }, ...{
      for (var drawing in favorites) drawing['id']: drawing
    }};

    return allDrawings.values.where((drawing) {
      final title = drawing['title']?.toString().toLowerCase() ?? '';
      final tags = drawing['tags']?.toString().toLowerCase() ?? '';
      return title.contains(query.toLowerCase()) ||
          tags.contains(query.toLowerCase());
    }).toList();
  }

  // Statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final prefs = await SharedPreferences.getInstance();

    final recentJson = prefs.getString(_recentKey);
    final favoritesJson = prefs.getString(_favoritesKey);
    final metadataJson = prefs.getString(_metadataKey);

    final int totalDrawings = recentJson != null
        ? List.from(json.decode(recentJson)).length
        : 0;

    final int totalFavorites = favoritesJson != null
        ? Map.from(json.decode(favoritesJson)).length
        : 0;

    int totalAccessCount = 0;
    if (metadataJson != null) {
      final Map<String, dynamic> metadata = Map<String, dynamic>.from(json.decode(metadataJson));
      totalAccessCount = metadata.values.fold(0, (sum, data) {
        return sum + (data['accessCount'] ?? 0);
      });
    }

    return {
      'totalDrawings': totalDrawings,
      'totalFavorites': totalFavorites,
      'totalAccessCount': totalAccessCount,
      'averageAccessPerDrawing': totalDrawings > 0 ? totalAccessCount / totalDrawings : 0,
    };
  }

  // Cleanup
  static Future<void> clearOldDrawings({int daysOld = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    final recentJson = prefs.getString(_recentKey);
    if (recentJson != null) {
      final List<dynamic> recent = List<dynamic>.from(json.decode(recentJson));
      final List<dynamic> updatedRecent = recent.where((item) {
        final accessedAt = DateTime.parse(item['accessedAt']);
        return accessedAt.isAfter(cutoffDate);
      }).toList();

      await prefs.setString(_recentKey, json.encode(updatedRecent));
    }
  }

  // Export/Import
  static Future<String> exportData() async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> exportData = {
      'favorites': prefs.getString(_favoritesKey),
      'recent': prefs.getString(_recentKey),
      'metadata': prefs.getString(_metadataKey),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };

    return json.encode(exportData);
  }

  static Future<bool> importData(String importJson) async {
    try {
      final Map<String, dynamic> importData = Map<String, dynamic>.from(json.decode(importJson));
      final prefs = await SharedPreferences.getInstance();

      if (importData['favorites'] != null) {
        await prefs.setString(_favoritesKey, importData['favorites']);
      }

      if (importData['recent'] != null) {
        await prefs.setString(_recentKey, importData['recent']);
      }

      if (importData['metadata'] != null) {
        await prefs.setString(_metadataKey, importData['metadata']);
      }

      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }
}