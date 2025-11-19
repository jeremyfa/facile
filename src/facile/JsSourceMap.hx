package facile;

#if js
import haxe.Json;
import js.lib.Object;
#end

class JsSourceMap {

    #if js
    var sourceMap:Dynamic;
    var decodedMappings:Array<Array<MappingSegment>>;

    static var instance:JsSourceMap;
    static var initializationAttempted:Bool = false;

    public function new(sourceMapJson:String) {
        this.sourceMap = Json.parse(sourceMapJson);
        this.decodedMappings = null;
    }

    public static function getInstance():JsSourceMap {
        if (!initializationAttempted) {
            initializationAttempted = true;
            autoDiscoverAndLoad();
        }
        return instance;
    }

    public static function setSourceMap(sourceMapJson:String):Void {
        instance = new JsSourceMap(sourceMapJson);
    }

    /**
     * Auto-discover and load source map from the current script
     */
    static function autoDiscoverAndLoad():Void {
        js.Syntax.code("
            (function() {
                var sourceMapUrl = null;
                var scriptUrl = null;

                // Browser environment
                if (typeof window !== 'undefined' && typeof document !== 'undefined') {
                    // Try to find the current script
                    var scripts = document.getElementsByTagName('script');

                    // Method 1: Check document.currentScript
                    if (document.currentScript && document.currentScript.src) {
                        scriptUrl = document.currentScript.src;
                    }
                    // Method 2: Look for scripts with source map comments
                    else {
                        // Check all script tags for inline source map comments
                        for (var i = scripts.length - 1; i >= 0; i--) {
                            var script = scripts[i];
                            if (script.src) {
                                // Check if this script has a .map file
                                var potentialMapUrl = script.src + '.map';
                                scriptUrl = script.src;
                                break;
                            } else if (script.textContent) {
                                // Check for sourceMappingURL comment in inline scripts
                                var match = script.textContent.match(/\\/\\/#\\s*sourceMappingURL=(.+?)\\s*$/m);
                                if (match) {
                                    sourceMapUrl = match[1];
                                    break;
                                }
                            }
                        }
                    }

                    // If we found a script URL, try loading its source map
                    if (scriptUrl && !sourceMapUrl) {
                        sourceMapUrl = scriptUrl + '.map';
                    }

                    // Load the source map via XHR
                    if (sourceMapUrl) {
                        var xhr = new XMLHttpRequest();
                        xhr.open('GET', sourceMapUrl, true);
                        xhr.onload = function() {
                            if (xhr.status === 200) {
                                try {
                                    {0}(xhr.responseText);
                                } catch (e) {
                                    // Failed to parse source map
                                }
                            }
                        };
                        xhr.send();
                    }
                }
                // Node.js environment
                else if (typeof process !== 'undefined' && process.versions && process.versions.node) {
                    try {
                        var fs = require('fs');
                        var path = require('path');

                        // Get the main script path
                        var mainScript = process.argv[1] || require.main.filename;

                        if (mainScript) {
                            // Try to read the JS file to find sourceMappingURL
                            var jsContent = fs.readFileSync(mainScript, 'utf8');
                            var match = jsContent.match(/\\/\\/#\\s*sourceMappingURL=(.+?)\\s*$/m);

                            if (match) {
                                var mapFile = match[1];
                                // Resolve relative path
                                if (!path.isAbsolute(mapFile)) {
                                    mapFile = path.join(path.dirname(mainScript), mapFile);
                                }
                                sourceMapUrl = mapFile;
                            } else {
                                // Default: assume it's mainScript + '.map'
                                sourceMapUrl = mainScript + '.map';
                            }

                            // Try to load the source map
                            if (sourceMapUrl && fs.existsSync(sourceMapUrl)) {
                                var sourceMapContent = fs.readFileSync(sourceMapUrl, 'utf8');
                                {1}(sourceMapContent);
                            }
                        }
                    } catch (e) {
                        // Failed to auto-discover in Node.js
                    }
                }
            })();
        ", setSourceMap, setSourceMap);
    }

    function decodeVLQ(string:String, index:Int):{value:Int, nextIndex:Int} {
        var VLQ_BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        var result = 0;
        var shift = 0;
        var continuation = true;
        var digit:Int;

        while (continuation) {
            if (index >= string.length) {
                throw "Invalid VLQ sequence";
            }

            var char = string.charAt(index++);
            digit = VLQ_BASE64_CHARS.indexOf(char);

            if (digit == -1) {
                throw "Invalid base64 character: " + char;
            }

            continuation = (digit & 32) != 0;
            digit &= 31;
            result += digit << shift;
            shift += 5;
        }

        var shouldNegate = (result & 1) != 0;
        result >>= 1;

        return {
            value: shouldNegate ? -result : result,
            nextIndex: index
        };
    }

    function decodeMappings():Array<Array<MappingSegment>> {
        if (decodedMappings != null) {
            return decodedMappings;
        }

        var mappings:String = sourceMap.mappings;
        var lines = mappings.split(";");
        var result:Array<Array<MappingSegment>> = [];

        var sourceIndex = 0;
        var sourceLine = 0;
        var sourceColumn = 0;
        var nameIndex = 0;

        for (lineIndex in 0...lines.length) {
            var line = lines[lineIndex];
            var segments = line.split(",");
            var lineResult:Array<MappingSegment> = [];
            var generatedColumn = 0;

            for (segment in segments) {
                if (segment == "") continue;

                var segmentData:MappingSegment = {
                    generatedLine: lineIndex,
                    generatedColumn: 0
                };
                var index = 0;

                var decoded = decodeVLQ(segment, index);
                generatedColumn += decoded.value;
                segmentData.generatedColumn = generatedColumn;
                index = decoded.nextIndex;

                if (index < segment.length) {
                    decoded = decodeVLQ(segment, index);
                    sourceIndex += decoded.value;
                    segmentData.sourceIndex = sourceIndex;
                    index = decoded.nextIndex;

                    decoded = decodeVLQ(segment, index);
                    sourceLine += decoded.value;
                    segmentData.sourceLine = sourceLine;
                    index = decoded.nextIndex;

                    decoded = decodeVLQ(segment, index);
                    sourceColumn += decoded.value;
                    segmentData.sourceColumn = sourceColumn;
                    index = decoded.nextIndex;

                    if (index < segment.length) {
                        decoded = decodeVLQ(segment, index);
                        nameIndex += decoded.value;
                        segmentData.nameIndex = nameIndex;
                    }
                }

                lineResult.push(segmentData);
            }

            result.push(lineResult);
        }

        decodedMappings = result;
        return result;
    }

    public function getOriginalPosition(line:Int, column:Int = 0):OriginalPosition {
        var mappings = decodeMappings();

        var lineIndex = line - 1;

        if (lineIndex < 0 || lineIndex >= mappings.length) {
            return null;
        }

        var lineMapping = mappings[lineIndex];
        if (lineMapping == null || lineMapping.length == 0) {
            return null;
        }

        var closestMapping:MappingSegment = null;

        for (mapping in lineMapping) {
            if (mapping.generatedColumn <= column) {
                closestMapping = mapping;
            } else {
                break;
            }
        }

        if (closestMapping == null || closestMapping.sourceIndex == null) {
            return null;
        }

        var sources:Array<String> = sourceMap.sources;
        var source = sources[closestMapping.sourceIndex];

        if (StringTools.startsWith(source, 'file://')) {
            source = source.substring('file://'.length);
        }

        // Not so sure why we have so many slashes
        while (StringTools.startsWith(source, '//')) {
            source = source.substring(1);
        }

        var result:OriginalPosition = {
            source: source,
            line: closestMapping.sourceLine + 1,
            column: closestMapping.sourceColumn
        };

        if (closestMapping.nameIndex != null && sourceMap.names != null) {
            var names:Array<String> = sourceMap.names;
            result.name = names[closestMapping.nameIndex];
        }

        return result;
    }
    #end
}

#if js
typedef MappingSegment = {
    generatedLine:Int,
    generatedColumn:Int,
    ?sourceIndex:Int,
    ?sourceLine:Int,
    ?sourceColumn:Int,
    ?nameIndex:Int
}

typedef OriginalPosition = {
    source:String,
    line:Int,
    column:Int,
    ?name:String
}
#end
