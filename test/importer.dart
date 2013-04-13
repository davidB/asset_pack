/*
  Copyright (C) 2013 John McCutchan <john@johnmccutchan.com>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

part of asset_pack_tests;

class Importer {
  static final AssetPackTrace trace = new AssetPackTrace();
  static void textTest() {
    TextLoader textLoader = new TextLoader();
    test('text', () {
      Future loaded;
      var asset = new Asset(null, 'test', '', 'test.json',
                            'json', null, {}, null, {});
      loaded = textLoader.load(asset, trace);
      loaded.then(expectAsync1((String text) {
        expect(text == null, false);
        TextImporter importer = new TextImporter();
        importer.import(text, asset, trace).then((asset) {
          String expected = '{"a":[1,2,3]}';
          expect(asset.imported.startsWith(expected), true);
        });
      }));
    });
  }

  static void jsonTest() {
    TextLoader textLoader = new TextLoader();
    test('map', () {
      Future loaded;
      var assetRequest = new Asset(null, 'map', '', 'map.json',
                                   'json', null, {}, null, {});
      loaded = textLoader.load(assetRequest, trace);
      loaded.then(expectAsync1((String text) {
        expect(text == null, false);
        JsonImporter importer = new JsonImporter();
        importer.import(text, assetRequest, trace).then((asset) {
          expect(asset.imported['a'], 'b');
        });
      }));
    });
    test('list', () {
      Future loaded;
      var assetRequest = new Asset(null, 'list', '', 'list.json',
                                   'json', null, {}, null, {});
      loaded = textLoader.load(assetRequest, trace);
      loaded.then(expectAsync1((String text) {
        expect(text == null, false);
        JsonImporter importer = new JsonImporter();
        importer.import(text, assetRequest, trace).then((asset) {
          expect(asset.imported.length, 5);
        });
      }));
    });
  }

  static void runTests() {
    group('TextImporter', () {
      Importer.textTest();
    });
    group('JsonImporter', () {
      Importer.jsonTest();
    });
  }
}
