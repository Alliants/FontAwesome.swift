#!/usr/bin/swift

import Foundation

typealias Icons = [String: Icon]

struct Icon: Codable {
    let styles: [String]
    let unicode: String
}

let keywordMappings: [String: String] = [
    "500px": "fiveHundredPixels",
    "0": "zero",
    "00": "doubleZero",
    "1": "one",
    "2": "two",
    "3": "three",
    "360-degrees": "threeHundredDegrees",
    "4": "four",
    "42-group": "fourtyTwoGroup",
    "5": "five",
    "6": "six",
    "7": "seven",
    "8": "eight",
    "9": "nine",
    "repeat": "`repeat`",
    "subscript": "`subscript`"
]

extension String {
    public func camelCased(with separator: Character) -> String {
        return split(separator: separator).reduce("") { result, element in
            "\(result)\(result.count > 0 ? String(element.capitalized) : String(element))"
        }
    }
    
    public func filteredKeywords() -> String {
        if let mappedKeyword = keywordMappings[self] {
            return mappedKeyword
        }
        return self
    }
}

func generateEnumAndUnicodeSwitches(from icons: Icons, isBrand: Bool = false) -> String {
    var fileContent = isBrand ? "public enum FontAwesomeBrands: String, CaseIterable {\n" : "public enum FontAwesome: String, CaseIterable {\n"
    
    let filteredKeys = isBrand ? icons.filter { $0.value.styles.contains("brands") }.keys.sorted() : icons.keys.sorted()
    
    filteredKeys.forEach { key in
        guard icons[key] != nil else { return }
        let enumCaseName = key.filteredKeywords().camelCased(with: "-")
        fileContent += "    case \(enumCaseName) = \"fa-\(key)\"\n"
    }
    
    fileContent += "\n    public var unicode: String {\n"
    fileContent += "        switch self {\n"
    
    filteredKeys.forEach { key in
        guard let value = icons[key] else { return }
        let enumCaseName = key.filteredKeywords().camelCased(with: "-")
        fileContent += "        case .\(enumCaseName): return \"\\u{\(value.unicode)}\"\n"
    }
    
    fileContent += "        }\n    }\n}\n\n"
    
    return fileContent
}


do {
    guard let json = FileManager.default.contents(atPath: "/Users/cristian/Downloads/fontawesome-pro-desktop/metadata/icons.json") else {
        fatalError("Could not find JSON metadata file")
    }
    
    let icons = try JSONDecoder().decode(Icons.self, from: json)
    
    let enumAndSwitches = generateEnumAndUnicodeSwitches(from: icons)
    let brandEnumAndSwitches = generateEnumAndUnicodeSwitches(from: icons, isBrand: true)
    
    let fontAwesomeEnums = enumAndSwitches + brandEnumAndSwitches
  
    let filePath = "/Users/cristian/Dev/Enum.swift"

    if FileManager.default.createFile(atPath: filePath, contents: fontAwesomeEnums.data(using: .utf8), attributes: nil) {
        print("File created atPath: \(filePath)")
    } else {
        print("Couldtn create file atPath: \(filePath)")

    }
} catch {
    print("Error: \(error.localizedDescription)")
}

