import 'dart:io';
import 'dart:json';
import 'package:asset_pack/asset_pack_file.dart';

AssetPackFile openAssetPackFile(String path) {
  File out = new File(path);
  String contents;
  try {
    contents = out.readAsStringSync();
  } catch (_) {
    print('Could not open existing asset pack file.');
    print('Creating new assset pack.');
    // Return empty asset pack file.
    return new AssetPackFile();
  }
  List<Map> json;
  try {
    json = JSON.parse(contents);
  } catch (e) {
    print(e);
    print('Could not parse existing asset pack file.');
    print('Creating new assset pack.');
    // Return empty asset pack file.
    return new AssetPackFile();
  }
  print('Loaded existing asset pack file.');
  return new AssetPackFile.fromJson(json);
}


main() {
  bool verbose = true;
  Options options = new Options();
  String inPath;
  if (options.arguments.length == 0) {
    inPath = '/Users/johnmccutchan/workspace/assetpack/test/testpack';
  } else {
    inPath = options.arguments[0];
  }
  String outPath = '$inPath.pack';
  AssetPackFile packFile = openAssetPackFile(outPath);
  List<AssetPackFileAsset> assets = packFile.assets.values;
  assets.sort((a, b) => Comparable.compare(a.name, b.name));
  assets.sort((a, b) => Comparable.compare(a.type, b.type));
  int count = 0;
  assets.forEach((f) {
    var name = f.name;
    var url = f.url;
    var type = f.type;
    print('$count $name $type ($url)');
    if (verbose) {
      print('$count   L: ${f.loadArguments}');
      print('$count   I: ${f.importArguments}');
    }
    count++;
  });
}