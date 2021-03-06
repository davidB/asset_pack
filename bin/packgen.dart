import 'dart:io';
import 'dart:json' as JSON;
import 'package:asset_pack/asset_pack_file.dart';

/// Configuration file for generating .pack files
class PackGenConfig {
  /// Serialization name for type
  static const String _typeName = 'type';
  /// Serialization name for import arguments
  static const String _importArgumentsName = 'importArguments';
  /// Serialization name for load arguments
  static const String _loadArgumentsName = 'loadArguments';

  Map _values;

  /// Creates the default configuration.
  ///
  /// No explicit import or export arguments are specified.
  ///
  ///     getAssetType('json') == 'json';
  ///     getAssetType('txt')  == 'text';
  PackGenConfig() {
    _values = new Map();

    // Add json file connection
    Map jsonMap = new Map();
    jsonMap[_typeName] = 'json';

    _values['json'] = jsonMap;

    // Add text file connection
    Map textMap = new Map();
    textMap[_typeName] = 'text';

    _values['txt'] = textMap;

    // Add pack file connection
    Map packMap = new Map();
    packMap[_typeName] = 'pack';

    _values['pack'] = packMap;
  }

  /// Loads a configuration data from a file at the given [path].
  PackGenConfig.fromPath(Path path) {
    // Read the file
    File configFile = new File.fromPath(path);
    String contents;

    try {
      contents = configFile.readAsStringSync();
    } catch (_) {
      print('Could not open existing config file.');
    }

    // Parse it as JSON
    try {
      _values = JSON.parse(contents);
    } catch (_) {
      print('Could not parse config file.');
      _values = new Map();
    }
  }

  String getType(String extension) {
    String value = _getConfigValue(extension, _typeName);

    return (value != null) ? value : '';
  }

  Map getImportArguments(String extension) {
    Map value = _getConfigValue(extension, _importArgumentsName);

    return (value != null) ? value : new Map();
  }

  Map getLoadArguments(String extension) {
    Map value = _getConfigValue(extension, _loadArgumentsName);

    return (value != null) ? value : new Map();
  }

  dynamic _getConfigValue(String extension, String configValue) {
    if (_values.containsKey(extension)) {
      Map extensionMap = _values[extension];

      if (extensionMap.containsKey(configValue)) {
        return extensionMap[configValue];
      }
    }

    return null;
  }
}

AssetPackFile openAssetPackFile(String path) {
  File out = new File.fromPath(new Path(path));
  String contents;
  try {
    contents = out.readAsStringSync();
  } catch (_) {
    print('Could not open existing asset pack file.');
    print('Creating new assset pack.');
    // Return empty asset pack file.
    return new AssetPackFile();
  }
  var json;
  try {
    json = JSON.parse(contents);
  } catch (_) {
    print('Could not parse existing asset pack file.');
    print('Creating new assset pack.');
    // Return empty asset pack file.
    return new AssetPackFile();
  }
  print('Loaded existing asset pack file.');
  return new AssetPackFile.fromJson(json);
}

void merge(AssetPackFile packFile,
           List<String> assetPaths,
           PackGenConfig configuration
           ) {
  assetPaths.forEach((assetPath) {
    Path path = new Path(assetPath);
    String name = path.filenameWithoutExtension;
    String url = assetPath;

    if (name == '_') {
      name = path.directoryPath.filenameWithoutExtension;
    }
    if (packFile.assets.containsKey(name)) {
      print('Old asset pack already has $name');
      return;
    }
    if (name == '') {
      print('Skipping $url because it has no name.');
      return;
    }

    String extension = path.extension;
    String type = configuration.getType(extension);
    Map importArguments = configuration.getImportArguments(extension);
    Map loadArguments = configuration.getLoadArguments(extension);

    print('Adding new asset $name ($url) (type=$type) $extension');
    packFile.assets[name] = new AssetPackFileAsset(name, url, type,
        importArguments, loadArguments);
  });
  packFile.assets.values.where((v) =>
    !assetPaths.contains(v.url)
  ).toList().forEach((v) {
    print('Removing asset ${v.name} which no longer exists.');
    packFile.assets.remove(v.name);
  });
}

void output(AssetPackFile packFile, String path) {
  File out = new File.fromPath(new Path(path));
  RandomAccessFile raf;
  try {
    raf = out.openSync(mode: FileMode.WRITE);
  } catch (e) {
    print('Could not open $path for writing. $e');
    return;
  }
  String serialized;
  try {
    serialized = JSON.stringify(packFile);
  } catch (_) {
    print('Could not serialize pack file into JSON');
    return;
  }
  print('Writing packfile to: $path');
  raf.writeStringSync(serialized);
  raf.closeSync();
}

void main() {
  Options options = new Options();
  String pathString;
  PackGenConfig configuration;

  // There are some workarounds required for running on Windows
  bool isWindows = Platform.operatingSystem == 'windows';

  if (options.arguments.length == 0) {
    print('Usage: dart packgen.dart <path> [config].');
    return;
  } else {
    pathString = options.arguments[0];

    if (options.arguments.length == 2) {
      configuration = new PackGenConfig.fromPath(new Path(options.arguments[1]));
    } else {
      configuration = new PackGenConfig();
    }
  }

  // Always have a / at the end of the path.
  pathString = '$pathString\/';
  Path path = new Path(pathString).directoryPath;

  // If the path is not absolute create the absolute path
  if (path.isAbsolute == false) {
    Directory working = Directory.current;
    Path fullPath = new Path(working.path);
    path = fullPath.join(path);
  }

  path = path.canonicalize();

  String packPathString = '${path}/_.pack';
  print('Scanning $path for assets.');
  print('Adding assets to $packPathString');
  List<String> assetPaths = new List<String>();
  Directory dir = new Directory.fromPath(path);
  pathString = path.toString();

  // On Windows the path string is prefixed with a '/' but the results
  // of File.fullPathSync are not prefixed with that. To do the
  // matching the '/' must be removed.
  if (isWindows) {
    pathString = pathString.substring(1);
  }

  int pathStringLength = pathString.length;
  dir.listSync(recursive:true).forEach((listing) {
    if (listing is File) {
      String filePathString = listing.fullPathSync();

      // On Windows File.fullPathSync returns a string with '\' as the
      // path separator. Modify to use '/'
      if (isWindows) {
        filePathString = filePathString.replaceAll('\\', '/');
      }

      // Workaround for pub symbolic links
      // Doesn't work on Windows as symbolic links don't switch the path.
      // \todo Maybe check for a packages directory?
      if (filePathString.startsWith(pathString) && filePathString != packPathString) {
        assetPaths.add(filePathString.substring(pathStringLength+1));
      }
    }
  });

  AssetPackFile packFile = openAssetPackFile(packPathString);
  merge(packFile, assetPaths, configuration);
  output(packFile, packPathString);
}
